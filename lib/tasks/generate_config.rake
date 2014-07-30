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
  # TODO(jmink) Add ec2 support
  VALID_PROVIDERS = ['vagrant']

  def initialize(args, file_name)
    @options = validate_arguments(args)
    config = get_config
    # TODO(jmink) Error handling?
    File.open(file_name, 'w') do |file|
      file.write JSON.pretty_generate(modify_config(config))
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

  def modify_config(config)
    # TODO(jmink) Deal with provider's other than vagrant
    config["provider"] = @options.provider
    config["vagrant_options"]["box"] = "opscode-#{@options.platform}"
    # TODO(jmink) Look this up so it isn't hard coded
    config["vagrant_options"]["box_url"] = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box" 
    # TODO(jmink) Integrate this with Oliver's changes so it isn't hard coded
    config["default_package"] = "private-chef_11.1.5+20140717085251.git.176.ade25af-1_amd64.deb"
    # TODO(jmink) Obey topology
    # TODO(jmink) Deal with Open source vs. private chef server

    config
  end

  
end
