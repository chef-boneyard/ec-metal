# encoding: utf-8

require 'chef_metal'
require 'chef/server_api'
require 'chef_metal_fog'

def whyrun_supported?
  true
end

use_inline_resources

def cloud_machine_created?(vmname)
  rest = Chef::ServerAPI.new()
  begin
    nodeinfo = rest.get("/nodes/#{vmname}")
  rescue Net::HTTPServerException
    # Handle the 404 meaning the machine hasn't been created yet
    nodeinfo = {'normal' => { 'metal' => {} } }
  end
  driver_info = nodeinfo['normal']['metal']['location'] || {}
  return true if driver_info.has_key?('server_id')
  false
end

action :cloud_create do
 # Dumb hack to populate all of our machines first, for dynamic name/IP provisioners
  machine_batch 'cloud_create' do
    action [:converge]
    topo = TopoHelper.new(ec_config: node['harness']['vm_config'])
    topo.merged_topology.each do |vmname, config|

      next if cloud_machine_created?(vmname)
      machine vmname do
        add_machine_options node['harness']['provisioner_options'][vmname]
        attribute 'private-chef', privatechef_attributes
        attribute 'root_ssh', node['harness']['root_ssh'].to_hash
        attribute 'cloud', cloud_attributes('ec2')
        recipe 'private-chef::hostname'
        recipe 'private-chef::ec2'
      end

    end
  end
end

action :install do
  topo = TopoHelper.new(ec_config: node['harness']['vm_config'], exclude_layers: ['analytics'])
  topo.merged_topology.each do |vmname, config|
    machine_batch vmname do
      action [:converge]

      machine vmname do
        add_machine_options node['harness']['provisioner_options'][vmname]
        attribute 'private-chef', privatechef_attributes
        attribute 'root_ssh', node['harness']['root_ssh'].to_hash

        recipe 'private-chef::hostname'
        recipe 'private-chef::hostsfile'
        recipe 'private-chef::provision'
        recipe 'private-chef::bugfixes' if node['harness']['apply_ec_bugfixes'] == true
        recipe 'private-chef::drbd' if
          node['harness']['vm_config']['topology'] == 'ha' &&
          topo.is_backend?(vmname)
        recipe 'private-chef::provision_phase2'
        recipe 'private-chef::users' if
          vmname == topo.bootstrap_node_name
        recipe 'private-chef::reporting' if node['harness']['reporting_package']
        recipe 'private-chef::manage' if node['harness']['manage_package'] &&
          topo.is_frontend?(vmname)
        recipe 'private-chef::pushy' if node['harness']['pushy_package']
        recipe 'private-chef::tools'

        converge true
      end
    end
  end

  if node['harness']['analytics_package'] && node['harness']['vm_config']['analytics']
    node['harness']['vm_config']['analytics'].each do |vmname, config|
      machine_batch vmname do
        action [:converge]

        machine vmname do
          add_machine_options node['harness']['provisioner_options'][vmname]
          attribute 'private-chef', privatechef_attributes
          attribute 'root_ssh', node['harness']['root_ssh'].to_hash

          recipe 'private-chef::hostname'
          recipe 'private-chef::hostsfile'
          recipe 'private-chef::analytics'

          converge true
        end
      end
    end
  end

end

action :stop_all_but_master do
  topo = TopoHelper.new(ec_config: node['harness']['vm_config'], exclude_layers: ['analytics'])
  topo.merged_topology.each do |vmname, config|
    next if config['bootstrap'] == true # all backends minus bootstrap

    # with_machine_options node['harness']['provisioner_options'][vmname]
    machine_execute "p-c-c_stop_on_#{vmname}" do
      command '/opt/opscode/bin/private-chef-ctl stop ; exit 0'
      machine vmname
    end

  end
end

action :start_non_bootstrap do
  topo_be = TopoHelper.new(ec_config: node['harness']['vm_config'], include_layers: ['backends'])
  topo_be.merged_topology.each do |vmname, config|
    next if config['bootstrap'] == true # all backends minus bootstrap

    machine_execute "p-c-c_start_keepalived_on_#{vmname}" do
      command '/opt/opscode/bin/private-chef-ctl start keepalived ; exit 0'
      machine vmname
    end
  end

  topo_fe = TopoHelper.new(ec_config: node['harness']['vm_config'], include_layers: ['frontends'])
  topo_fe.merged_topology.each do |vmname, config|
    machine_execute "p-c-c_start_on_#{vmname}" do
      command '/opt/opscode/bin/private-chef-ctl start ; exit 0'
      machine vmname
    end
  end
end

action :destroy do
  machine_batch do
    action :destroy
    machines search(:node, '*:*').map { |n| n.name }
  end
end

def installer_path(ec_package)
  return nil unless ec_package
  return ec_package if ::URI.parse(ec_package).absolute?
  ::File.join(node['harness']['vm_mountpoint'], ec_package)
end

def privatechef_attributes
  packages = package_attributes
  attributes = node['harness']['vm_config'].to_hash
  attributes['configuration'] = {} unless attributes['configuration']
  attributes['installer_file'] = packages['ec']
  unless packages['manage'] == nil
    attributes['manage_installer_file'] = packages['manage']
    attributes['configuration']['opscode_webui'] = { 'enable' => false }
  end
  attributes['reporting_installer_file'] = packages['reporting']
  attributes['pushy_installer_file'] = packages['pushy']
  unless packages['analytics'] == nil
    attributes['analytics_installer_file'] = packages['analytics']
    attributes['configuration']['dark_launch'] = { 'actions' => true }
    attributes['configuration']['rabbitmq'] = {
      'vip' => attributes['backend_vip']['ipaddress'],
      'node_ip_address' => '0.0.0.0'
    }
  end
  attributes
end

def cloud_attributes(provider)
  cloud_attrs = node['harness'][provider].to_hash
  cloud_attrs['provider'] = provider

  case provider
  when 'ec2'
    aws_credentials = ChefMetalFog::Providers::AWS::Credentials.new
    aws_credentials.load_default
    cloud_attrs['aws_access_key_id'] ||= aws_credentials.default[:aws_access_key_id]
    cloud_attrs['aws_secret_access_key'] ||= aws_credentials.default[:aws_secret_access_key]
  end

  cloud_attrs
end

def package_attributes
  packages = {}

  if new_resource.ec_package
    packages['ec'] = installer_path(new_resource.ec_package)
  else
    packages['ec'] = installer_path(node['harness']['default_package'])
  end
  packages['manage'] = installer_path(node['harness']['manage_package'])
  packages['reporting'] = installer_path(node['harness']['reporting_package'])
  packages['pushy'] = installer_path(node['harness']['pushy_package'])
  packages['analytics'] = installer_path(node['harness']['analytics_package'])

  packages
end
