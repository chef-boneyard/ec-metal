# encoding: utf-8

ec_harness_private_chef_ha "stop_all_but_bootstrap_on_#{node['harness']['provider']}" do
  action :stop_all_but_master
end

ec_harness_private_chef_ha "stop_all_but_bootstrap_on_#{node['harness']['provider']}" do
  action :install
end