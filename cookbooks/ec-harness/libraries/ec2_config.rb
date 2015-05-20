# encoding: utf-8

class Ec2ConfigHelper

  def initialize(params = {})
    @root_block_device = String.new
  end


  # parameters for chef-provisioning-fog
  def self.generate_config(vmname, config, node)

    # override all keypair settings if passed as env var
    keypair_name = ENV['ECM_KEYPAIR_NAME'] || "#{ENV['USER']}@#{::File.basename(node['harness']['harness_dir'])}"
    ami_id = config['ami_id'] || node['harness']['ec2']['ami_id']
    @root_block_device ||= FogHelper.new(ami: ami_id, region: node['harness']['ec2']['region']).get_root_blockdevice

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
          {'DeviceName' => @root_block_device,
            'Ebs.VolumeSize' => 12,
            'Ebs.VolumeType' => 'gp2',
            'Ebs.DeleteOnTermination' => "true"},
          {'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0'}
        ],
        :tags => {
          'EcMetal' => node['harness']['ec2']['ec_metal_tag']
        }
      },
      :convergence_options => {
        :install_sh_arguments => '-P chefdk'
      }
    }

  end

  # For the aws-sdk style chef-provisioning-aws
  def self.generate_config_aws(vmname, config, node)

    # override all keypair settings if passed as env var
    keypair_name = ENV['ECM_KEYPAIR_NAME'] || "#{ENV['USER']}@#{::File.basename(node['harness']['harness_dir'])}"
    ami_id = config['ami_id'] || node['harness']['ec2']['ami_id']
    @root_block_device ||= FogHelper.new(ami: ami_id, region: node['harness']['ec2']['region']).get_root_blockdevice

    local_provisioner_options = {
      :ssh_username => config['ssh_username'] || node['harness']['ec2']['ssh_username'],
      :use_private_ip_for_ssh => node['harness']['ec2']['use_private_ip_for_ssh'],
      :bootstrap_options => {
        :key_name => keypair_name,
        :instance_type => config['instance_type'] || 'm3.xlarge',
        :ebs_optimized => config['ebs_optimized'] || false,
        :image_id => ami_id,
        :subnet_id => config['vpc_subnet'] || node['harness']['ec2']['vpc_subnet'],
        :associate_public_ip_address => true,
        :block_device_mappings => [
          { device_name: @root_block_device,
            ebs: {
              volume_size: 12,
              volume_type: 'gp2',
              delete_on_termination: true
            }
          },
          {device_name: '/dev/sdb', virtual_name: 'ephemeral0'}
        ],
        # :tags => {
        #   'EcMetal' => node['harness']['ec2']['ec_metal_tag']
        # }
      },
      :convergence_options => {
        :install_sh_arguments => '-P chefdk'
      }
    }

  end

end
