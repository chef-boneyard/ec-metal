# encoding: utf-8

require 'cheffish'
require 'chef_metal_fog'

harness_dir = node['harness']['harness_dir']
repo_path = node['harness']['repo_path']

with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [ ENV['ECM_LOCAL_COOKBOOKS'],
                      File.join(repo_path, 'cookbooks'),
    File.join(repo_path, 'vendor', 'cookbooks') ].uniq,
    :port => 9010.upto(9999)

with_driver "fog:AWS:default:#{node['harness']['ec2']['region']}"
# alternative method:
# with_driver 'fog:AWS:default', :compute_options => {
#   :region => node['harness']['ec2']['region'],
# }

with_machine_options :ssh_username => node['harness']['ec2']['ssh_username'],
  :use_private_ip_for_ssh => node['harness']['ec2']['use_private_ip_for_ssh']


# override all keypair settings if passed as env var
node.set['harness']['ec2']['keypair_name'] = ENV['ECM_KEYPAIR_NAME'] unless ENV['ECM_KEYPAIR_NAME'].nil?

keypair_name = node['harness']['ec2']['keypair_name'] || "#{ENV['USER']}@#{::File.basename(harness_dir)}"

fog_key_pair keypair_name do
  private_key_path File.join(repo_path, 'keys', 'id_rsa')
  public_key_path File.join(repo_path, 'keys', 'id_rsa.pub')
end

# set provisioner options for all of our machines
topo = TopoHelper.new(ec_config: node['harness']['vm_config'])
topo.merged_topology.each do |vmname, config|
  fog_helper = FogHelper.new(ami: node['harness']['ec2']['ami_id'], region: node['harness']['ec2']['region'])

  local_provisioner_options = {
    :bootstrap_options => {
      :key_name => keypair_name,
      :flavor_id => config['instance_type'] || 'c3.large',
      :region => node['harness']['ec2']['region'],
      :ebs_optimized => config['ebs_optimized'] || false,
      :image_id => node['harness']['ec2']['ami_id'],
      :subnet_id => node['harness']['ec2']['vpc_subnet'],
      :associate_public_ip => true,
      :block_device_mapping => [
        {'DeviceName' => fog_helper.get_root_blockdevice,
          'Ebs.VolumeSize' => 12,
          'Ebs.VolumeType' => 'gp2',
          'Ebs.DeleteOnTermination' => "true"},
        {'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0'}
      ]
    }
  }

  node.set['harness']['provisioner_options'][vmname] = local_provisioner_options
end

# Precreate cloud machines, for dynamic discovery later on
ec_harness_private_chef_ha "cloud_create_for_EC2" do
  action :cloud_create
  not_if { node['recipes'].include?('ec-harness::cleanup') }
end
