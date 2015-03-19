# encoding: utf-8

include_recipe 'ec-harness::cloud_create'

include_recipe 'ec-harness::bootstrap_server'
include_recipe 'ec-harness::cluster_servers'
include_recipe 'ec-harness::analytics_servers'



if node['harness']['run_pedant'] == true
  include_recipe 'ec-harness::pedant'
end
