#
# Author: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
# All Rights Reserved
#

installer_file = node['private-chef']['reporting_installer_file']
installer_name = ::File.basename(installer_file)

# reporting currently only works if the env var is specified
installer_path = installer_file

package installer_name do
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform?("ubuntu","debian")
  action :install
end

execute "reconfigure-reporting" do
  command "opscode-reporting-ctl reconfigure"
  action :run
end

