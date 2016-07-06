# Shamelessly copied from the reporting.rb recipe

installer_file = node['private-chef']['pushy_installer_file']
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
  provider Chef::Provider::Package::Dpkg if platform_family?('debian')
  action :install
end

execute "reconfigure-pushy" do
  command "opscode-push-jobs-server-ctl reconfigure --accept-license"
  action :run
end
