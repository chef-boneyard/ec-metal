node.default['chef']['config']['chef_server_root'] = "https://#{node['private-chef']['manage_fqdn']}"

include_recipe 'ec-tools::knife-opc'