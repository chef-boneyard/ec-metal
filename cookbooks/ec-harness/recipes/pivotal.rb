include_recipe "ec-harness::#{node['harness']['provider']}"

ec_harness_private_chef_ha "get pivotal" do
  action :pivotal
end
