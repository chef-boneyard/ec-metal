# encoding: utf-8

require 'chef_metal'
require 'chef/server_api'
require 'chef_metal_fog'

def whyrun_supported?
  true
end

use_inline_resources

def harness_config
  data_bag_item 'harness', 'config'
end

def root_ssh
  data_bag_itme 'harness', 'root_ssh'
end

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
  harness = harness_config
  machine_batch 'cloud_create' do
    action [:converge]
    topo = TopoHelper.new(ec_config: harness['layout'])
    topo.merged_topology.each do |vmname, config|

      next if cloud_machine_created?(vmname)
      machine vmname do
        add_machine_options node['harness']['provisioner_options'][vmname]
        attribute 'private-chef', privatechef_attributes
        attribute 'root_ssh', root_ssh.to_hash
        attribute 'cloud', cloud_attributes('ec2')
        recipe 'private-chef::hostname'
        recipe 'private-chef::ec2'
      end

    end
  end
end

action :install do
  harness = harness_config
  topo = TopoHelper.new(ec_config: harness['layout'], exclude_layers: ['analytics'])
  topo.merged_topology.each do |vmname, config|
    machine_batch vmname do
      action [:converge]

      machine vmname do
        add_machine_options node['harness']['provisioner_options'][vmname]
        attribute 'private-chef', privatechef_attributes
        attribute 'root_ssh', root_ssh.to_hash
        attribute 'osc-install', harness['osc_install']
        attribute 'osc-upgrade', harness['osc_upgrade']

        recipe 'private-chef::hostname'
        recipe 'private-chef::hostsfile'
        recipe 'private-chef::provision'
        recipe 'private-chef::bugfixes' if harness['apply_ec_bugfixes'] == true
        recipe 'private-chef::drbd' if topo.is_backend?(vmname) and topo.is_ha?
        recipe 'private-chef::provision_phase2'
        recipe 'private-chef::users' if vmname == topo.bootstrap_node_name &&
          node['harness']['osc_install'] == false
        recipe 'private-chef::reporting' if harness['reporting_package']
        recipe 'private-chef::manage' if harness['manage_package'] &&
          topo.is_frontend?(vmname)
        recipe 'private-chef::pushy' if harness['pushy_package']
        recipe 'private-chef::tools'
        # this doesn't work 
        # ohai_hints { 'ec2' } 
        # but this does
        file '/etc/chef/ohai/hints/ec2.json', { :content => '' } # work around until chef-metal-fog PR is merged

        converge true
      end
    end
  end

  if harness['analytics_package'] && harness['vm_config']['analytics']
    harness['layout']['analytics'].each do |vmname, config|
      machine_batch vmname do
        action [:converge]

        machine vmname do
          add_machine_options node['harness']['provisioner_options'][vmname]
          attribute 'private-chef', privatechef_attributes
          attribute 'root_ssh', root_ssh.to_hash

          recipe 'private-chef::hostname'
          recipe 'private-chef::hostsfile'
          recipe 'private-chef::analytics'

          converge true
        end
      end
    end
  end

end

action :pedant do
  harness = harness_config
  topo = TopoHelper.new(ec_config: harness['layout'], exclude_layers: ['analytics'])
  topo.merged_topology.each do |vmname, config|
    machine_batch vmname do
      action [:converge]

      machine vmname do
        add_machine_options node['harness']['provisioner_options'][vmname]
        attribute 'private-chef', privatechef_attributes
        attribute 'root_ssh', root_ssh.to_hash
        attribute 'osc-install', harness['osc_install']
        attribute 'run-pedant', harness['run_pedant']

        recipe 'private-chef::pedant'

        converge true
      end
    end
  end
end

# bin/knife opc -c chef-repo/pivotal/knife-pivotal.rb user list
action :pivotal do

  harness = harness_config
  directory ::File.join(harness['repo_path'], 'pivotal')

  topo = TopoHelper.new(ec_config: harness['layout'])

  machine_execute 'read pivotal.pem for vagrant' do
    command 'sudo chmod 644 /etc/opscode/pivotal.pem'
    machine topo.bootstrap_node_name
    only_if { harness['provider'] == 'vagrant' }
  end

  machine_file '/etc/opscode/pivotal.pem' do
    local_path ::File.join(harness['repo_path'], 'pivotal', 'pivotal.pem')
    machine topo.bootstrap_node_name
    action :download
  end

  bootstrap_node_data = search(:node, "name:#{topo.bootstrap_node_name}")

  ipaddress = nil
  if harness['provider'] == 'ec2'
    ipaddress = bootstrap_node_data[0][:ec2][:public_ipv4]
  elsif harness['provider'] == 'vagrant'
    ipaddress = bootstrap_node_data[0][:network][:interfaces][:eth1][:routes][0][:src]
  else
    raise ArgumentError, "Unsupported provider #{harness['provider']}. Can't get ip address."
  end

  template ::File.join(harness['repo_path'], 'pivotal', 'knife-pivotal.rb') do
    source 'knife-pivotal.rb.erb'
    variables ({
      :ipaddress => ipaddress
    })
  end
end

action :stop_all_but_master do
  harness = harness_config
  topo = TopoHelper.new(ec_config: harness['layout'], exclude_layers: ['analytics'])
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
  harness = harness_config
  topo_be = TopoHelper.new(ec_config: harness['layout'], include_layers: ['backends'])
  topo_be.merged_topology.each do |vmname, config|
    next if config['bootstrap'] == true # all backends minus bootstrap

    machine_execute "p-c-c_start_keepalived_on_#{vmname}" do
      command '/opt/opscode/bin/private-chef-ctl start keepalived ; exit 0'
      machine vmname
    end
  end

  topo_fe = TopoHelper.new(ec_config: harness['layout'], include_layers: ['frontends'])
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
  harness = harness_config
  packages = package_attributes
  attributes = harness['layout'].to_hash
  attributes['configuration'] = {} unless attributes['configuration']
  attributes['installer_file'] = packages['ec']
  unless packages['manage'] == nil
    attributes['manage_installer_file'] = packages['manage']
    attributes['configuration']['opscode_webui'] = { 'enable' => false }
    attributes['manage_options'] = node['harness']['manage_options']
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
  harness = harness_config

  if new_resource.ec_package
    packages['ec'] = installer_path(new_resource.ec_package)
  else
    packages['ec'] = installer_path(harness['default_package'])
  end
  packages['manage'] = installer_path(harness['manage_package'])
  packages['reporting'] = installer_path(harness['reporting_package'])
  packages['pushy'] = installer_path(harness['pushy_package'])
  packages['analytics'] = installer_path(harness['analytics_package'])

  packages
end
