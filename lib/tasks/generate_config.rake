require 'json'

desc 'Create a config based on passed in vars'
task :create_config, [:topology, :variant, :version, :platform] => [:config_copy, :bundle] do |t,arg|
  if arg.topology.nil? || arg.variant.nil? || arg.version.nil? || arg.platform.nil?
    abort("ERROR: All arguments required")
  end

  GenerateConfig.new(arg, 'generated_config.json')
end


class GenerateConfig
  def initialize(args, file_name)
    # TODO(jmink) argument validation
    @options = args
    config = get_config
    # TODO(jmink) Error handling?
    File.open(file_name, 'w') do |file|
      file.write JSON.pretty_generate(modify_config(config))
    end
  end

  def modify_config(config)
    # TODO(jmink) Deal with provider's other than vagrant
    config["vagrant_options"]["box"] = "opscode-#{@options.platform}"
    # TODO(jmink) Look this up so it isn't hard coded
    config["vagrant_options"]["box_url"] = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box" 
    # TODO(jmink) Integrate this with Oliver's changes so it isn't hard coded
    config["default_package"] = "private-chef_11.1.5+20140717085251.git.176.ade25af-1_amd64.deb"
    # TODO(jmink) Obey topology

    config
  end

  
end
