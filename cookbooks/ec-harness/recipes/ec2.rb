# encoding: utf-8

require 'cheffish'
require 'chef_metal_fog'

repo_path = node['harness']['repo_path']

with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [ File.join(repo_path, 'cookbooks'),
    File.join(repo_path, 'vendor', 'cookbooks') ]

with_fog_ec2_provisioner :ssh_username => node['harness']['ec2']['ssh_username'],
    'region' => node['harness']['ec2']['region']

with_provisioner_options 'bootstrap_options' => {
      'image_id' => node['harness']['ec2']['ami_id']
    }

fog_key_pair "#{ENV['USER']}@ec-ha" do
  private_key_path File.join(repo_path, 'keys', 'id_rsa')
  public_key_path File.join(repo_path, 'keys', 'id_rsa.pub')
end

# set provisioner options for all of our machines
node['harness']['vm_config']['backends'].merge(
  node['harness']['vm_config']['frontends']).each do |vmname, config|

  local_provisioner_options = {
    'bootstrap_options' => {
      'flavor_id' => config['instance_type'] || 'c3.large',
      'ebs_optimized' => config['ebs_optimized'] || false,
      'image_id' => node['harness']['ec2']['ami_id'],
      'subnet_id' => node['harness']['ec2']['vpc_subnet'],
      'associate_public_ip' => true,
      # this doesn't work, because https://github.com/aws/aws-cli/issues/520
      # 'private_ip_address' => config['ipaddress'],
      'block_device_mapping' => [{'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0'}]
    }
  }

  node.set['harness']['provisioner_options'][vmname] = ChefMetal.enclosing_provisioner_options.merge(local_provisioner_options)

end