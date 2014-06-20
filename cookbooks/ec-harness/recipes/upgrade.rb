# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

ec_harness_private_chef_ha "stop_all_but_bootstrap_on_#{node['harness']['provider']}" do
  action :stop_all_but_master
end

ec_harness_private_chef_ha "install_#{node['harness']['default_package']}_on_#{node['harness']['provider']}" do
  action :install
end

ec_harness_private_chef_ha "start_non_bootstrap_on_#{node['harness']['provider']}" do
  action :start_non_bootstrap
end