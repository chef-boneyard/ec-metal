require 'json'

require './lib/config_generation/generate_ec2_config.rb'
require './lib/config_generation/generate_vagrant_config.rb'


# TODO(jmink) Take another look at these variable names/how they're passed in
desc 'Create a config based on passed in vars'
task :create_config, [:topology, :variant, :platform, :provider] => [:config_copy, :bundle] do |t,args|
  ECMetal::Config.from_hash(args)
  ECMetal::Config.from_env
  EcMetal::GenerateConfig.create('generated_config.json')
end
