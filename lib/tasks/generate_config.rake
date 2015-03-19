require 'json'

require './lib/config_generation/generate_config.rb'


# TODO(jmink) Take another look at these variable names/how they're passed in
desc 'Create a config based on passed in vars'
task :create_config, [:topology, :variant, :platform, :provider] do |t,args|
  args.with_defaults(:topology => 'standalone', :variant => 'private_chef',
      :platform => 'ubuntu-12.04', :provider => 'vagrant')

  EcMetal::GenerateConfig.create_by_provider(args.provider, args, 'generated_config.json')
end
