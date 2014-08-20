require 'json'

require './lib/config_generation/generate_vagrant_config.rb'
require './lib/config_generation/generate_ec2_config.rb'

VALID_TOPOS = ['ha', 'standalone', 'tier']
VALID_VARIANTS = ['private_chef', 'chef_server']
VALID_PROVIDERS = ['vagrant', 'ec2']

# TODO(jmink) Take another look at these variable names/how they're passed in
desc 'Create a config based on passed in vars'
task :create_config, [:topology, :variant, :platform, :provider] => [:config_copy, :bundle] do |t,args|
  args.with_defaults(:topology => 'standalone', :variant => 'private_chef',
      :platform => 'ubuntu-12.04', :provider => 'vagrant')

  validate_arguments(args)
 
  case args.provider
  when 'vagrant'
    GenerateVagrantConfig.new(args, 'generated_config.json')
  when 'ec2'
    GenerateEc2Config.new(args, 'generated_config.json')
  end
end

  def validate_arguments(args)
    if args.topology.nil? || args.variant.nil? || args.platform.nil? || args.provider.nil?
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
  end
