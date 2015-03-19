# encoding: utf-8
# in clusters stands up the remaining backends and frontends in parallel

include_recipe "ec-harness::#{node['harness']['provider']}"

if node['harness']['analytics_package'] && is_analytics?
  ecm_topo_analytics.merged_topology.each do |vmname, config|
    machine_batch vmname do
      action [:converge]

      machine vmname do
        machine_options machine_options_for_provider(vmname, config)
        attribute 'private-chef', privatechef_attributes
        attribute 'analytics', analytics_attributes
        attribute 'root_ssh', node['harness']['root_ssh'].to_hash

        recipe 'private-chef::hostname'
        recipe 'private-chef::hostsfile'
        recipe 'private-chef::analytics'

        converge true
      end
    end
  end
end
