require './lib/config_generation/generate_config.rb'

class GenerateEc2Config < GenerateConfig

  # EC2 notes:
  # Think about using smaller instances/test (near term)
  # This is based on:
  # http://docs.getchef.com/enterprise/install_server_be.html

  # TODO(jmink) Move this data to a shared location
  EC2_DATA = {
    :default_subnet_id => 'subnet-c88354ad',
    :default_region => 'us-west-2',
    :image_map => {

      # Debian
      'debian-6' => 'ami-8ef27fbe', # ebs-magnetic
      'debian-7' => 'ami-40760270', # ebs-magnetic

      # Debian 32-bit
      'debian-6-i386' => 'ami-8ef27fbe', # ebs-magnetic
      'debian-7-i386' => 'ami-a0760290', # ebs-magnetic

      # FreeBSD
      'freebsd-9'  => 'ami-26f96716', # ebs-magnetic
      'freebsd-10' => 'ami-e8b4d5d8', # ebs-magnetic

      # openSUSE
      'opensuse-12' => 'ami-62cd4452', # ebs-magnetic

      # openSUSE 32-bit
      'opensuse-12-i386' => 'ami-c6ca43f6', # ebs-magnetic

      # RedHat
      'rhel-5' => 'ami-9ce27cac', # ebs-magnetic
      'rhel-6' => 'ami-aa8bfe9a', # ebs-magnetic

      # RedHat 32-bit
      'rhel-5-i386' => 'ami-62e27c52', # ebs-magnetic
      'rhel-6-i386' => 'ami-dc8ffaec', # ebs-magnetic

      # Centos
      'el-6'     => 'ami-937502a3', #ebs-magnetic

      # SLES
      'sles-11-sp2' => 'ami-e42da0d4', # ebs-magnetic
      'sles-11-sp3' => 'ami-d8b429e8', # ebs-magnetic

      # SLES 32-bit
      'sles-11-sp2-i386' => 'ami-fe2da0ce', # ebs-magnetic
      'sles-11-sp3-i386' => 'ami-9eb429ae', # ebs-magnetic

      # Ubuntu
      'ubuntu-10.04' => 'ami-3b45370b', # ebs-magnetic
      'ubuntu-11.04' => 'ami-0eb23b3e', # ebs-magnetic
      'ubuntu-12.04' => 'ami-c3abd6f3', # ebs-ssd
      'ubuntu-13.04' => 'ami-36d6b006', # ebs-magnetic
      'ubuntu-13.10' => 'ami-2daad71d', # ebs-ssd
      'ubuntu-14.04' => 'ami-ddaed3ed', # ebs-ssd

      # Ubuntu 32-bit
      'ubuntu-10.04-i386' => 'ami-39453709', # ebs-magnetic
      'ubuntu-11.04-i386' => 'ami-0ab23b3a', # ebs-magnetic
      'ubuntu-12.04-i386' => 'ami-4fc9b67f', # ebs-ssd
      'ubuntu-13.04-i386' => 'ami-34d6b004', # ebs-magnetic
      'ubuntu-13.10-i386' => 'ami-8588f6b5', # ebs-ssd
      'ubuntu-14.04-i386' => 'ami-8daed3bd', # ebs-ssd
    }
  }

  PLATFORM_TO_SSH_USER = {
    'rhel' => 'ec2-user',
    'ubuntu' => 'ubuntu',
  }
  DEFAULT_SSH_USER = 'root'

  def set_provider_data()
    ami = EC2_DATA[:image_map][@options.platform]
    abort("Invalid platform.  Can not determine ami") if ami.nil?
    @config['ec2_options'] = {
        :region => EC2_DATA[:default_region],
        :vpc_subnet => EC2_DATA[:default_subnet_id],
        :ami_id => ami,
        :ssh_username => ssh_username(@options.platform),
        :use_private_ip_for_ssh => false }

    @config['ec2_options']['keypair_name'] = ENV['ECM_KEYPAIR_NAME'] unless ENV['ECM_KEYPAIR_NAME'].nil?
  end

  def ssh_username(platform)
    PLATFORM_TO_SSH_USER.keys.each do |key|
      return PLATFORM_TO_SSH_USER[key] if platform.include? key
    end
    DEFAULT_SSH_USER
  end

  def generate_backend(n)
    {
      :hostname => "backend#{n}.opscode.piab",
      :instance_type => "c3.xlarge",
      :ebs_optimized => true
    }
  end

  def generate_frontend(n)
    {
      :hostname => "frontend#{n}.opscode.piab",
      :ebs_optimized => false,
      :instance_type => "m3.medium"
    }
  end

  def provider_specific_config_modification
  end

  def backend_vip_device
    "eth0"
  end

  def backend_vip_heartbeat_device
    "eth0"
  end
end
