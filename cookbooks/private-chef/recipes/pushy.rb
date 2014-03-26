# Shamelessly copied from the reporting.rb recipe

installer_path = node['private-chef']['pushy_installer_file']
installer_name = ::File.basename(installer_path)

package installer_name do
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform?("ubuntu","debian")
  action :install
end

execute "reconfigure-pushy" do
  command "opscode-push-jobs-server-ctl reconfigure"
  action :run
end
