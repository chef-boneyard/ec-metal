
case node['platform_family']
when 'debian'
  include_recipe 'apt'
when 'rhel'
  include_recipe 'yum'
end

include_recipe 'lvm::default'

private_chef_backend_storage 'drbd_el_traditicional' do
  action :drbd
end