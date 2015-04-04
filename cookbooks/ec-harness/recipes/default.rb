# encoding: utf-8

include_recipe 'ec-harness::cloud_create' if node['harness']['provider'] == 'ec2'

# Converge the bootstrap or standalone server first
include_recipe 'ec-harness::bootstrap_server'
# converge the rest of the machines in the cluster (if any) in parallel
include_recipe 'ec-harness::cluster_servers'
# then bring up the analytics servers
include_recipe 'ec-harness::analytics_servers'

if node['harness']['run_pedant'] == true
  include_recipe 'ec-harness::pedant'
end
