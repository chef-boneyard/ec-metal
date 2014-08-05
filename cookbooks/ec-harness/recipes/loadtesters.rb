# encoding: utf-8

require 'chef/config'

include_recipe "ec-harness::#{node['harness']['provider']}"

topo = TopoHelper.new(ec_config: node['harness']['vm_config'], exclude_layers: ['loadtesters'])

# use bootstrap_host_name - it should be in /etc/hosts already
# rsync the /srv/piab/users dir down to harness dir
# use pem from signing dir

private_key_path = ::File.join(node['harness']['repo_path'], 'keys', 'id_rsa')
users_path = ::File.join(node['harness']['harness_dir'], 'users')
chef_org = 'ponyville'
chef_org_validation_pem = ::File.join(users_path, "#{chef_org}-validator.pem")
chef_user = 'pinkiepie'
chef_user_pem = ::File.join(users_path, chef_user, '.chef', "#{chef_user}.pem")
chef_server = ::Resolv.getaddress(topo.bootstrap_host_name)
chef_server_url = "https://#{chef_server}/organizations/#{chef_org}"
harness_knife_bin = ::File.join(node['harness']['harness_dir'], 'bin', 'knife')
harness_knife_config = ::File.join(node['harness']['harness_dir'], '.chef', 'knife.rb')
berks_bin = ::File.join(node['harness']['harness_dir'], 'bin', 'berks')
berks_config = ::File.join(node['harness']['repo_path'], 'berks_config.json')

# OMG please save me from the below horribleness
execute 'rsync user keys' do
  command "rsync -avz --delete -e 'ssh -i #{private_key_path}' root@#{chef_server}:/srv/piab/users/ #{users_path}"
  action :run
end

execute 'ghetto-cookbook-uploader' do
  command "#{harness_knife_bin} upload /cookbooks -s #{chef_server_url} -k #{chef_user_pem} -u #{chef_user} -c #{harness_knife_config}"
  action :run
end

berks_config_json = {
  chef: {
    chef_server_url: chef_server_url,
    node_name: chef_user,
    client_key: chef_user_pem
  },
  ssl: {
    verify: false
  }
}

file berks_config do
  action :create
  content JSON.pretty_generate(berks_config_json)
end

execute 'ghetto-berks-install' do
  command "#{berks_bin} install -c #{berks_config}"
  cwd node['harness']['harness_dir']
  action :run
end

execute 'ghetto-berks-uploader' do
  command "#{berks_bin} upload -c #{berks_config}"
  cwd node['harness']['harness_dir']
  action :run
end


# finally back to the task at hand
with_chef_server chef_server_url,
                 client_name: chef_user,
                 signing_key_filename: chef_user_pem

machine_batch 'fly_my_pretties_fly' do
  action [:converge]

    node['harness']['vm_config']['loadtesters'].each do |vmname, config|

      1.upto(20) do |i|
        machine "irving-loadtester-#{i}" do
          add_machine_options node['harness']['provisioner_options'][vmname]
          attribute 'root_ssh', node['harness']['root_ssh'].to_hash

          recipe 'docker_host::default'
          file '/etc/chef/validation.pem', chef_org_validation_pem
          # converge true
        end
      end

    end

end