# encoding: utf-8
# stands up the bootstrap host or only host in Standalone configurations

include_recipe "ec-harness::#{node['harness']['provider']}"

machine_batch 'bootstrap_node' do
  action [:converge]

  # Only do the bootstrap node in this batch
  ecm_topo_chef.merged_topology.select { |k,v| k == ecm_topo_chef.bootstrap_node_name }.each do |vmname, config|

    machine vmname do
      machine_options machine_options_for_provider(vmname, config)
      attribute 'private-chef', privatechef_attributes
      attribute 'root_ssh', node['harness']['root_ssh'].to_hash
      attribute 'osc-install', node['harness']['osc_install']
      attribute 'osc-upgrade', node['harness']['osc_upgrade']

      recipe 'private-chef::hostname'
      recipe 'private-chef::hostsfile'
      recipe 'private-chef::rhel'
      recipe 'private-chef::provision'
      recipe 'private-chef::bugfixes' if node['harness']['apply_ec_bugfixes'] == true
      recipe 'private-chef::drbd' if ecm_topo_chef.is_backend?(vmname)
      recipe 'private-chef::provision_phase2'
      recipe 'private-chef::reporting' if node['harness']['reporting_package']
      recipe 'private-chef::manage' if node['harness']['manage_package'] &&
        ecm_topo_chef.is_frontend?(vmname)
      recipe 'private-chef::pushy' if node['harness']['pushy_package']
      recipe 'private-chef::tools'
      recipe 'private-chef::users' if vmname == ecm_topo_chef.bootstrap_node_name
      recipe 'private-chef::loadbalancer' if ecm_topo_chef.is_frontend?(vmname) &&
        node['harness']['provider'] == 'ec2'
      recipe 'private-chef::org_torture' if node['harness']['org_torture'] == true

      converge true
    end
  end
end
