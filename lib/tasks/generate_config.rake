require 'json'

# TODO(jmink) Take another look at these variable names/how they're passed in
desc 'Create a config based on passed in vars'
task :create_config, [:topology, :variant, :version, :platform, :provider] => [:config_copy, :bundle] do |t,args|
  args.with_defaults(:topology => 'standalone', :variant => 'private_chef',
      :platform => 'ubuntu-12.04', :provider => 'vagrant')

  GenerateConfig.new(args, 'generated_config.json')
end


class GenerateConfig
  VALID_TOPOS = ['ha', 'standalone', 'tier']
  VALID_VARIANTS = ['private_chef', 'chef_server']
  VALID_PROVIDERS = ['vagrant', 'ec2']

  # TODO(jmink) Move this data to a shared location
  EC2_DATA = {
    :default_subnet_id => 'subnet-fc73b499',
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

  def initialize(args, file_name)
    @options = validate_arguments(args)
    @config = {}
    modify_config()
    # TODO(jmink) Error handling?
    File.open(file_name, 'w') do |file|
      file.write JSON.pretty_generate @config
    end
  end

  def validate_arguments(args)
    if args.topology.nil? || args.variant.nil? || args.version.nil? || args.platform.nil? || args.provider.nil?
      abort("ERROR: All arguments required")
    end

    unless VALID_PROVIDERS.include? args.provider
      abort("ERROR: #{args.provider} not recognized.  Valid providers are #{VALID_PROVIDERS.join(', ')}")
    end

    unless VALID_TOPOS.include? args.topology
      abort("ERROR: #{args.topology} not recognized.  Valid topos are #{VALID_TOPOS.join(', ')}")
    end

    unless VALID_VARIANTS.include? args.variant
      abort("ERROR: #{args.variant} not recognized.  Valid variants are #{VALID_VARIANTS.join(', ')}")
    end

    args
  end

  def modify_config()
    set_provider_data()

    # TODO(jmink) handle upgrade packages correctly
    # TODO(jmink) Error handling
    @config["default_package"] = ENV['EM_INITIAL_PACKAGE_NAME'] || ENV['EM_TARGET_PACKAGE_NAME']
    # TODO(jmink) handle manage package and analytics package as needed

    @config[:packages] = {}
    set_topology()

    # TODO(jmink) Deal with any weird open source bits & ensure upgrade is set up correctly
  end

  def set_provider_data()
    @config["provider"] = @options.provider
    case @options.provider
    when 'vagrant'
      @config["vagrant_options"] = {
          :box => "opscode-#{@options.platform}",
          :disk2_size => 2,
          # TODO(jmink) There must be a better way
          :box_url => "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_#{@options.platform}_chef-provisionerless.box" }
    when 'ec2'
      ami = EC2_DATA[:image_map][@options.platform]
      abort("Invalid platform.  Can not determine ami") if ami.nil?
      @config['ec2_options'] = {
          :region => EC2_DATA[:default_region],
          :vpc_subnet => EC2_DATA[:default_subnet_id],
          :ami_id => ami,
          :ssh_username => 'root',
          :use_private_ip_for_ssh => false }
    end
  end

  def set_topology()
    @config[:layout] = { :topology => @options.topology }
    # TODO(jmink) Fill out the whole structure
    case @options.topology
    when 'ha'
    when 'standalone'
    when 'tier'
    end
  end
end
