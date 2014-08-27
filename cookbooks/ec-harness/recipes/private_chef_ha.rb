# encoding: utf-8

harness = data_bag_item 'harness', 'config'

include_recipe "ec-harness::#{harness['provider']}"

ec_harness_private_chef_ha "install_#{harness['default_package']}_on_#{harness['provider']}" do
  action :install
end

ec_harness_private_chef_ha "run_pedant_on_#{harness['provider']}" do
  action :pedant
end
