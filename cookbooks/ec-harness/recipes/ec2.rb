# encoding: utf-8

require 'cheffish'
require 'chef_metal_fog'

repo_path = node['harness']['repo_path']

with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [ File.join(repo_path, 'cookbooks'),
    File.join(repo_path, 'vendor', 'cookbooks') ]

with_fog_ec2_provisioner :ssh_username => node['harness']['ec2']['ssh_username']

with_provisioner_options :bootstrap_options => {
    'image_id' => node['harness']['ec2']['ami_id'],
    'flavor_id' => node['harness']['ec2']['backend_instance_type'],
    'region' => node['harness']['ec2']['region']
  }

fog_key_pair 'me' do
  private_key_path File.join(repo_path, 'keys', 'ec2_key')
  public_key_path File.join(repo_path, 'keys', 'ec2_key.pub')
end

# set provisioner options for all of our machines
node['harness']['vm_config']['backends'].merge(
  node['harness']['vm_config']['frontends']).each do |vmname, config|

  local_provisioner_options = {
  }

  node.set['harness']['provisioner_options'][vmname] = ChefMetal.enclosing_provisioner_options.merge(local_provisioner_options)

end