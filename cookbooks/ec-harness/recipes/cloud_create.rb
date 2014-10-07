include_recipe "ec-harness::#{node['harness']['provider']}"

ec_harness_private_chef_ha "launch ec2 instances" do
  action :cloud_create
end