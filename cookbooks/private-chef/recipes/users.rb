installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)

if installer_name =~ /^private-chef/
  ec11_users 'foo' do
    action :create
    not_if { ::File.exists?('/srv/piab/dev_users_created') }
  end
end
