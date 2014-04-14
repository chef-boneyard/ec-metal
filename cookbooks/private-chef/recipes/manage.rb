# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
# All Rights Reserved
#

installer_file = node['private-chef']['manage_installer_file']
installer_name = ::File.basename(installer_file)

# manage currently only works if the env var is specified
installer_path = installer_file

package installer_name do
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform?("ubuntu","debian")
  action :install
end

file '/opt/opscode/sv/opscode-webui/keepalive_me' do
  action :delete
end

# assumes non-ha setting. if this is ha, manage is going to have issues
execute "reconfigure-private-chef-for-manage" do
  command "private-chef-ctl reconfigure"
  action :run
end

execute "reconfigure-manage" do
  command "opscode-manage-ctl reconfigure"
  action :run
end

