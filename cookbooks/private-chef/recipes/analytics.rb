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

