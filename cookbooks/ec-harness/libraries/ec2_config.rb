# encoding: utf-8

class Ec2ConfigHelper

  def initialize(params = {})
    @root_block_device = String.new
  end

  # For the aws-sdk style chef-provisioning-aws
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
          }
        ] + ephemeral_volumes(config['instance_type'])
      },
      :aws_tags => node['harness']['ec2']['tags'], # expecting a hash of tags
      :convergence_options => {
        :install_sh_arguments => '-P chefdk',
        :root => '/opt/chefdk'
      }
    }
  end

  def self.ephemeral_volumes(instance_type)
    ephemeral_volumes = []
    number_volumes = instance_type_ephemeral_vols(instance_type)
    return ephemeral_volumes if number_volumes == 0
    1.upto(number_volumes).each do |i|
      array_pos = i - 1
      ephemeral_volumes << {device_name: diskmap[array_pos], virtual_name: "ephemeral#{array_pos}" }
    end
    ephemeral_volumes
  end

  def self.diskmap
    ('b'..'z').map { |l| "sd#{l}" }
  end

  def self.instance_type_ephemeral_vols(instance_type)
    case instance_type
    when 'i2.8xlarge'
      8
    when 'i2.4xlarge'
      4
    when 'm3.xlarge', 'm3.2xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'r3.8xlarge', 'i2.2xlarge'
      2
    when 'm3.medium', 'm3.large', 'g2.2xlarge', 'r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge', 'i2.xlarge'
      1
    else
      0
    end
  end
end
