#
# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
# All Rights Reserved
#

installer_file = node['private-chef']['reporting_installer_file']
installer_name = ::File.basename(installer_file.split('?').first)
installer_path = "#{Chef::Config[:file_cache_path]}/#{installer_name}"

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

execute 'p-c-c-reconfigure-for-reporting' do
  command 'private-chef-ctl reconfigure'
  action :run
end


execute 'reconfigure-reporting' do
  command 'opscode-reporting-ctl reconfigure'
  action :run
end

