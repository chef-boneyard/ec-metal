case node['platform_family']
when 'debian'
  include_recipe 'apt'
when 'rhel'
  include_recipe 'yum'
end

include_recipe 'lvm::default'

if node['cloud'] && node['cloud']['provider'] == 'ec2' && node['cloud']['backend_storage_type'] == 'ebs'
  include_recipe 'aws'

  private_chef_backend_storage 'ebs_shared_storage' do
    action :ebs_shared
    only_if { node['private-chef']['backends'][node.name] }
    not_if { ::File.exists?('/var/opt/opscode/drbd/drbd_ready') }
  end

  private_chef_backend_storage 'ebs_save_databag' do
    action :ebs_save_databag
    only_if { node['private-chef']['backends'][node.name] &&
      node['private-chef']['backends'][node.name]['bootstrap'] == true }
    not_if { ::File.exists?('/var/opt/opscode/drbd/drbd_ready') }
  end
else
  private_chef_backend_storage 'drbd_el_traditicional' do
    action :drbd
  end
end