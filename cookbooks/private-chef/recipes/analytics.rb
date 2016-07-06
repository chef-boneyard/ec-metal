#
# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Author: Prajakta Purohit (<prajakta@getchef.com>)
# Copyright:: Copyright (c) 2013-2014 Opscode, Inc.
#
# All Rights Reserved
#

if node['cloud'] && node['cloud']['provider'] == 'ec2' && node['cloud']['backend_storage_type'] == 'ephemeral'
  include_recipe 'lvm::default'
  # Start+Enable the lvmetad service on RHEL7, it is enabled by default
  if node['platform_family'] == 'rhel' && node['platform_version'].to_i >= 7
    service 'lvm2-lvmetad' do
      action [:enable, :start]
      provider Chef::Provider::Service::Systemd
      only_if '/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1'
    end
  end

  private_chef_backend_storage 'ephemeral_data_store' do
    action :ephemeral_analytics
  end
end

installer_file = node['analytics']['analytics_installer_file']
installer_name = ::File.basename(installer_file.split('?').first)
installer_path = "#{Chef::Config[:file_cache_path]}/#{installer_name}"
analytics_topology = node['analytics']['analytics_topology']
topology = TopoHelper.new(ec_config: node['analytics'])

if ::URI.parse(installer_file).absolute?
  remote_file installer_path do
    source installer_file
    action :create_if_missing
  end
else
  installer_path = installer_file
end

package installer_name do
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform_family?('debian')
  action :install
end

# Terrible:  copied from provision.rb - factor me
# SSH key management for inter-node trust
directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

file '/root/.ssh/id_rsa' do
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  content node['root_ssh']['privkey']
end

file '/root/.ssh/authorized_keys' do
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  content node['root_ssh']['pubkey']
end

file '/root/.ssh/config' do
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  content "Host *\n  StrictHostKeyChecking no\n"
end

# RHEL-specific bug fixes
if node['platform_family'] == 'rhel'
  # Deal with RHEL-based boxes that may have their own firewalls up
  service 'iptables' do
    action [ :disable, :stop ]
  end

  # As of EC11.1.8, we need to disable sudo 'requiretty' on RHEL-based systems
  execute 'sudoers-disable-requiretty' do
    command 'sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers'
    action :run
    only_if 'grep "^Defaults.*requiretty" /etc/sudoers'
  end
end
# end Terrible

package 'rsync'

if (topology.analytics_bootstrap_node_name.include?(node.name) || analytics_topology == 'standalone')
  source = topology.bootstrap_host_name
elsif (topology.is_analytics_frontends?(node.name) || topology.is_analytics_workers?(node.name))
  source = topology.analytics_bootstrap_host_name
end


execute 'rsync-opscode-from-bootstrap' do
  command "rsync -avz -e ssh root@#{source}:/etc/opscode-analytics/ /etc/opscode-analytics"
  action :run
end

template '/etc/opscode-analytics/opscode-analytics.rb' do
  source 'opscode-analytics.rb.erb'
  owner 'root'
  group 'root'
  variables(
    :analytics_fqdn => node['private-chef']['analytics_fqdn']
  )
  action :create
  notifies :run, 'execute[reconfigure-analytics]', :immediately
end

execute 'reconfigure-analytics' do
  command 'opscode-analytics-ctl reconfigure --accept-license'
  action :run
end
