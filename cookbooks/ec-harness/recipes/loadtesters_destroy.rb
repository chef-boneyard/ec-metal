# encoding: utf-8

require 'chef/config'

# include_recipe "ec-harness::#{node['harness']['provider']}"

topo = TopoHelper.new(ec_config: node['harness']['vm_config'], exclude_layers: ['loadtesters'])

# use bootstrap_host_name - it should be in /etc/hosts already
# rsync the /srv/piab/users dir down to harness dir
# use pem from signing dir

users_path = ::File.join(node['harness']['harness_dir'], 'users')
chef_org = 'ponyville'
chef_user = 'pinkiepie'
chef_user_pem = ::File.join(users_path, chef_user, '.chef', "#{chef_user}.pem")
chef_server = ::Resolv.getaddress(topo.bootstrap_host_name)
chef_server_url = "https://#{chef_server}/organizations/#{chef_org}"


# finally back to the task at hand
with_chef_server chef_server_url,
                 client_name: chef_user,
                 signing_key_filename: chef_user_pem


machine_batch 'destroy_all_the_loadtesters' do
  action :destroy
      1.upto(10) do |i|
        machine "#{ENV['USER']}-loadtester-#{i}"
      end
end