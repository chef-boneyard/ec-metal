# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

ec_harness_private_chef_ha "run_pedant_on_#{node['harness']['provider']}" do
  action :pedant
end
