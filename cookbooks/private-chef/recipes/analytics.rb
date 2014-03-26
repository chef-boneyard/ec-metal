#
# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
# All Rights Reserved
#

installer_file = node['private-chef']['analytics_installer_file']
installer_name = ::File.basename(installer_file)

# analytics currently only works if the env var is specified
installer_path = installer_file

package installer_name do
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform?("ubuntu","debian")
  action :install
end

ruby_block "enable-analytics" do
  block do
    file = Chef::Util::FileEdit.new("/etc/opscode/private-chef.rb")
    file.insert_line_if_no_match("opscode_erchef\['enable_actionlog'\]", "opscode_erchef['enable_actionlog'] = true")
    file.write_file
  end
end

# assumes non-ha setting. if this is ha, analytics is going to have issues
execute "reconfigure-private-chef-for-analytics" do
  command "private-chef-ctl reconfigure"
  action :run
end

directory "/etc/opscode-analytics" do
  owner "root"
  group "root"
  action :create
end

template "/etc/opscode-analytics/opscode-analytics.rb" do
  source "opscode-analytics.rb.erb"
  owner "root"
  group "root"
  variables(
    :analytics_fqdn => node['private-chef']['analytics_fqdn']
  )
  action :create
  notifies :run, "execute[reconfigure-analytics]", :immediately
end

execute "reconfigure-analytics" do
  command "opscode-analytics-ctl reconfigure"
  action :run
end

