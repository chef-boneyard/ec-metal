# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

ec_harness_private_chef_ha "install_#{node['harness']['default_package']}_on_#{node['harness']['provider']}" do
  action :install
end

# skips pedant run if run_pedant is not present in config.json
if node['harness']['run_pedant']
  ec_harness_private_chef_ha "run_pedant_on_#{node['harness']['provider']}" do
    action :pedant
  end
end
