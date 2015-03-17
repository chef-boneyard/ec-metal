case node['platform_family']
when 'debian'
  include_recipe 'apt'
  package "linux-image-extra-#{node['kernel']['release']}" if node['cloud'] && node['cloud']['provider'] == 'ec2'
when 'rhel'
  include_recipe 'yum-epel'
  include_recipe 'yum-elrepo'
  # while we wait for the RHEL7.1 drbd module to get promoted to elrepo stable:
  include_recipe 'yum-elrepo::testing' if node['platform_version'].to_f == 7.1
  package 'psmisc'
end

include_recipe 'lvm::default'
# Start+Enable the lvmetad service on RHEL7, it is enabled by default
if node['platform_family'] == 'rhel' && node['platform_version'].to_i >= 7
  service 'lvm2-lvmetad' do
    action [:enable, :start]
    provider Chef::Provider::Service::Systemd
    only_if '/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1'
  end
end

topology = TopoHelper.new(ec_config: node['private-chef'])

if node['cloud'] && node['cloud']['provider'] == 'ec2' && node['cloud']['backend_storage_type'] == 'ebs'
  include_recipe 'aws'

  private_chef_backend_storage 'ebs_shared_storage' do
    if topology.is_ha?
      action :ebs_shared
    else
      action :ebs_standalone
    end
    only_if { topology.is_backend?(node.name) }
    not_if { ::File.exists?('/var/opt/opscode/drbd/drbd_ready') }
  end

  private_chef_backend_storage 'ebs_shared_storage' do
    action :set_ebs_volume_node_attribute
    only_if { topology.is_backend?(node.name) }
    not_if { node['aws'] &&
      node['aws']['ebs_volume'] &&
      node['aws']['ebs_volume'][topology.bootstrap_host_name] &&
      node['aws']['ebs_volume'][topology.bootstrap_host_name]['volume_id']
    }
  end

  template '/var/opt/opscode/keepalived/bin/ha_backend_storage' do
    source 'custom_backend_storage.ebs.erb'
    owner 'root'
    group 'root'
    mode '0700'
    variables ({
      :bootstrap_host_name => topology.bootstrap_host_name
      })
    only_if { topology.is_ha? }
    only_if { topology.is_backend?(node.name) }
  end
elsif topology.is_ha?
  private_chef_backend_storage 'drbd_el_traditicional' do
    action :drbd
  end
end

