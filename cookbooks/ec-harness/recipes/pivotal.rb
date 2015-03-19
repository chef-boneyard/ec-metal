include_recipe "ec-harness::#{node['harness']['provider']}"


directory ::File.join(node['harness']['repo_path'], 'pivotal')

machine_execute 'read pivotal.pem for vagrant' do
  command 'sudo chmod 644 /etc/opscode/pivotal.pem'
  machine ecm_topo_chef.bootstrap_node_name
  only_if { node['harness']['provider'] == 'vagrant' }
end

machine_file '/etc/opscode/pivotal.pem' do
  local_path ::File.join(node['harness']['repo_path'], 'pivotal', 'pivotal.pem')
  machine ecm_topo_chef.bootstrap_node_name
  action :download
end

bootstrap_node_data = search(:node, "name:#{ecm_topo_chef.bootstrap_node_name}")

ipaddress = nil
if node['harness']['provider'] == 'ec2'
  ipaddress = bootstrap_node_data[0][:ec2][:public_ipv4]
elsif node['harness']['provider'] == 'vagrant'
  ipaddress = bootstrap_node_data[0][:network][:interfaces][:eth1][:routes][0][:src]
else
  raise ArgumentError, "Unsupported provider #{node['harness']['provider']}. Can't get ip address."
end

template ::File.join(node['harness']['repo_path'], 'pivotal', 'knife-pivotal.rb') do
  source 'knife-pivotal.rb.erb'
  variables ({
    :ipaddress => ipaddress
  })
end
