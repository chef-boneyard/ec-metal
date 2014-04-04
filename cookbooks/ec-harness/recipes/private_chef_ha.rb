# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

ec_harness_private_chef_ha "install_#{node['harness']['default_package']}_on_#{node['harness']['provider']}" do
  action :install
end