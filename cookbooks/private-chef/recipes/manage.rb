# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
# All Rights Reserved
#

installer_file = node['private-chef']['manage_installer_file']
installer_name = ::File.basename(installer_file.split('?').first)
installer_path = "#{Chef::Config[:file_cache_path]}/#{installer_name}"

if installer_name =~ /chef-manage/
  manage_name = 'chef-manage'
else
  manage_name = 'opscode-manage'
end

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

file '/opt/opscode/sv/opscode-webui/keepalive_me' do
  action :delete
end

directory "/etc/#{manage_name}"

# string values need to be Strings in manage.rb
# this will likely break if ruby expressions are set in the config, TODO
manage_options = node['private-chef']['manage_options'].map { |key, value|
                   value = "\"#{value}\"" if value.is_a?(String)
                   "#{key} #{value}"
                 }.join("\n")

file "/etc/#{manage_name}/manage.rb" do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  content manage_options
end

# assumes non-ha setting. if this is ha, manage is going to have issues
execute "reconfigure-private-chef-for-manage" do
  command "private-chef-ctl reconfigure"
  action :run
end

if PackageHelper.package_version(installer_name) < '2.3.0'
  reconfigure_cmd = "#{manage_name}-ctl reconfigure"
else
  reconfigure_cmd = "#{manage_name}-ctl reconfigure --accept-license"
end

execute "reconfigure-manage" do
  command reconfigure_cmd
  action :run
end
