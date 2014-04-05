# encoding: utf-8

include_recipe "ec-harness::#{node['harness']['provider']}"

# TODO: Figure out an idempotent way to do this
node['harness']['packages'].each do |name, packagefile|

  unless name == node['harness']['packages'].keys.first
    ec_harness_private_chef_ha "stop_all_but_bootstrap_on_#{node['harness']['provider']}" do
      action :stop_all_but_master
    end
  end


  ec_harness_private_chef_ha "install_#{packagefile}_on_#{node['harness']['provider']}" do
    ec_package packagefile
    action :install
  end

end