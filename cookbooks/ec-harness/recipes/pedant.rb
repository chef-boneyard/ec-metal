# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

ecm_topo_chef.merged_topology.each do |vmname, config|

  # Skip on non-bootstrap backend
  # FIXME: this assumes no failover has occured, better to make it conditional
  next if ecm_topo_chef.is_backend?(vmname) && ecm_topo_chef.is_ha? &&
    config['bootstrap'] != true

  machine_execute "run_pedant_on#{vmname}" do
    command '/opt/opscode/bin/private-chef-ctl test'
    machine vmname
  end

end
