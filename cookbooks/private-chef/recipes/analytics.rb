#
# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
# All Rights Reserved
#

installer_file = node['private-chef']['analytics_installer_file']
installer_name = ::File.basename(installer_file.split('?').first)
installer_path = "#{Chef::Config[:file_cache_path]}/#{installer_name}"

bootstrap_host_name =
  node['private-chef']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.values.first['hostname']

bootstrap_node_name =
  node['private-chef']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.keys.first

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
  provider Chef::Provider::Package::Dpkg if platform?('ubuntu','debian')
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

if node.name != bootstrap_node_name
  execute 'rsync-opscode-from-bootstrap' do
    command "rsync -avz -e ssh root@#{bootstrap_host_name}:/etc/opscode-analytics/ /etc/opscode-analytics"
    action :run
  end
end

directory '/etc/opscode-analytics' do
  owner 'root'
  group 'root'
  action :create
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
  command 'opscode-analytics-ctl reconfigure'
  action :run
end

