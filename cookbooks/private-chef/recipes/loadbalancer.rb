# encoding: utf-8

private_chef_frontend_lb node.name do
  action :create
  only_if { TopoHelper.new(ec_config: node['private-chef']).is_frontend?(node.name) }
  only_if { node['cloud'] && node['cloud']['elb'] == true }
end