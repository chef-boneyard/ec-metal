# encoding: utf-8

def whyrun_supported?
  true
end

use_inline_resources

def bootstrap_node_name
  node['harness']['vm_config']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.keys.first
end

def installer_path(ec_package)
  ::File.join(node['harness']['vm_mountpoint'], ec_package)
end

def machine_attributes(installer_file)
  machine_attributes = {
    'private-chef' => node['harness']['vm_config'].to_hash,
    'root_ssh' => node['harness']['root_ssh'].to_hash
  }
  machine_attributes['private-chef']['installer_file'] = installer_file
  machine_attributes
end


action :install do

  if new_resource.ec_package
    installer_file = installer_path(new_resource.ec_package)
  else
    installer_file = installer_path(node['harness']['default_package'])
  end

  node['harness']['vm_config']['backends'].merge(
    node['harness']['vm_config']['frontends']).each do |vmname, config|

    # provisoner_options is set by your provisioner recipe (ex: vagrant.rb)
    ChefMetal.with_provisioner_options node['harness']['provisioner_options'][vmname]

    machine vmname do

      attributes machine_attributes(installer_file)

      recipe 'private-chef::hostsfile'
      recipe 'private-chef::provision'
      recipe 'private-chef::drbd' if node['harness']['vm_config']['backends'].include?(vmname)
      recipe 'private-chef::provision_phase2'
      recipe 'private-chef::users' if vmname == bootstrap_node_name

      action :create
    end
  end

end

action :upgrade do
end

action :stop_all_but_master do
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