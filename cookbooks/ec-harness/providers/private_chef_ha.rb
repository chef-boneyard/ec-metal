# encoding: utf-8

require 'chef_metal'

def whyrun_supported?
  true
end

use_inline_resources

def bootstrap_node_name
  node['harness']['vm_config']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.keys.first
end

def installer_path(ec_package)
  return ec_package if ::URI.parse(ec_package).absolute?
  ::File.join(node['harness']['vm_mountpoint'], ec_package)
end

def machine_attributes(packages)
  machine_attributes = {
    'private-chef' => node['harness']['vm_config'].to_hash,
    'root_ssh' => node['harness']['root_ssh'].to_hash
  }
  machine_attributes['private-chef']['installer_file'] = packages['ec']
  unless packages['manage'] == nil
    machine_attributes['private-chef']['manage_installer_file'] = packages['manage']
    machine_attributes['private-chef']['configuration'] = { opscode_webui: { enable: false } }
  end
  machine_attributes['private-chef']['reporting_installer_file'] = packages['reporting']
  machine_attributes['private-chef']['pushy_installer_file'] = packages['pushy']
  machine_attributes
end


action :install do

  packages = {}

  if new_resource.ec_package
    packages['ec'] = installer_path(new_resource.ec_package)
  else
    packages['ec'] = installer_path(node['harness']['default_package'])
  end

  # Addon packages
  if node['harness']['manage_package']
    packages['manage'] = installer_path(node['harness']['manage_package'])
  end
  if node['harness']['reporting_package']
    packages['reporting'] = installer_path(node['harness']['reporting_package'])
  end
  if node['harness']['pushy_package']
    packages['pushy'] = installer_path(node['harness']['pushy_package'])
  end

  # Dumb hack to populate all of our machines first, for dynamic name/IP provisioners
  if node['harness']['provider'] == 'ec2'
    node['harness']['vm_config']['backends'].each do |vmname, config|
      ChefMetal.with_provisioner_options node['harness']['provisioner_options'][vmname]

      machine vmname do
        attributes machine_attributes(packages)
        recipe 'private-chef::hostname'
      end
    end
  end

  node['harness']['vm_config']['backends'].merge(
    node['harness']['vm_config']['frontends']).each do |vmname, config|
    # provisoner_options is set by your provisioner recipe (ex: vagrant.rb)
    ChefMetal.with_provisioner_options node['harness']['provisioner_options'][vmname]

    machine vmname do
      attributes machine_attributes(packages)

      recipe 'private-chef::hostsfile'
      recipe 'private-chef::provision'
      recipe 'private-chef::drbd' if node['harness']['vm_config']['backends'].include?(vmname)
      recipe 'private-chef::provision_phase2'
      recipe 'private-chef::users' if vmname == bootstrap_node_name
      recipe 'private-chef::reporting' if node['harness']['reporting_package']
      recipe 'private-chef::manage' if node['harness']['manage_package'] &&
        node['harness']['vm_config']['frontends'].include?(vmname)
      recipe 'private-chef::pushy' if node['harness']['pushy_package']
    end
  end

end

action :stop_all_but_master do
  # all backends minus bootstrap
  node['harness']['vm_config']['backends'].
    select { |vmname, config| config['bootstrap'] != true }.merge(
    node['harness']['vm_config']['frontends']).each do |vmname, config|

    ChefMetal.with_provisioner_options node['harness']['provisioner_options'][vmname]
    machine_execute "p-c-c_stop_on_#{vmname}" do
      command '/opt/opscode/bin/private-chef-ctl stop ; exit 0'
      machine vmname
    end

  end
end

action :destroy do

  # Bring the backends and frontends online
  node['harness']['vm_config']['backends'].merge(
    node['harness']['vm_config']['frontends']).each do |vmname, config|

    machine vmname do
      action :delete
    end
  end

end