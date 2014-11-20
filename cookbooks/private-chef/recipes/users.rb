installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)
# topology = TopoHelper.new(ec_config: node['private-chef'])

# wait_for_ha_master 'private-chef::users' if topology.is_ha? # libraries/wait_for_ha.rb
# wait_for_server_ready 'private-chef::users' # libraries/wait_for_server_ready.rb

if installer_name =~ /^private-chef/
  ec11_users 'foo' do
    action :create
    not_if { ::File.exists?('/srv/piab/dev_users_created') }
  end
end
