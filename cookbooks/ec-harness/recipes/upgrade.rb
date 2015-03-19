# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

# Stop all but master
ecm_topo_chef.merged_topology.each do |vmname, config|
  next if config['bootstrap'] == true # all backends minus bootstrap

  # with_machine_options node['harness']['provisioner_options'][vmname]
  machine_execute "p-c-c_stop_on_#{vmname}" do
    command '/opt/opscode/bin/private-chef-ctl stop ; exit 0'
    machine vmname
  end
end

# install
include_recipe 'ec-harness::default'

# Start services
topo_be = TopoHelper.new(ec_config: node['harness']['vm_config'], include_layers: ['backends'])
topo_be.merged_topology.each do |vmname, config|
  machine_execute "p-c-c_start_keepalived_on_#{vmname}" do
    command '/opt/opscode/bin/private-chef-ctl start keepalived ; exit 0'
    machine vmname
  end
end

topo_fe = TopoHelper.new(ec_config: node['harness']['vm_config'], include_layers: ['frontends'])
topo_fe.merged_topology.each do |vmname, config|
  machine_execute "p-c-c_start_on_#{vmname}" do
    command '/opt/opscode/bin/private-chef-ctl start ; exit 0'
    machine vmname
  end
end
