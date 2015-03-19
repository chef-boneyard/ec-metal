# encoding: utf-8

class Ec2ConfigHelper

  def self.generate_config(vmname, config, node)

    # override all keypair settings if passed as env var
    keypair_name = ENV['ECM_KEYPAIR_NAME'] || "#{ENV['USER']}@#{::File.basename(harness_dir)}"

    fog_helper = FogHelper.new(ami: node['harness']['ec2']['ami_id'], region: node['harness']['ec2']['region'])

    local_provisioner_options = {
      :ssh_username => config['ssh_username'] || node['harness']['ec2']['ssh_username'],
      :use_private_ip_for_ssh => node['harness']['ec2']['use_private_ip_for_ssh'],
      :bootstrap_options => {
        :key_name => keypair_name,
        :flavor_id => config['instance_type'] || 'm3.xlarge',
        :region => node['harness']['ec2']['region'],
        :ebs_optimized => config['ebs_optimized'] || false,
        :image_id => config['ami_id'] || node['harness']['ec2']['ami_id'],
        :subnet_id => config['vpc_subnet'] || node['harness']['ec2']['vpc_subnet'],
        :associate_public_ip => true,
        :block_device_mapping => [
          {'DeviceName' => fog_helper.get_root_blockdevice,
            'Ebs.VolumeSize' => 12,
            'Ebs.VolumeType' => 'gp2',
            'Ebs.DeleteOnTermination' => "true"},
          {'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0'}
        ],
        :tags => {
          'EcMetal' => node['harness']['ec2']['ec_metal_tag']
        }
      }
    }

  end

end
