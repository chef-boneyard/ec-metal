require_relative 'provider_specific/provider_specific.rb'
require_relative 'knife_config.rb'

require "mixlib/shellout"
require 'pathname'
require 'bundler'

module EcMetal
  class Api

    MINUTE_IN_DEC_SECS = 600
    KNIFE = File.join(File.dirname(File.dirname(__FILE__)), '.chef', 'knife.rb')

    attr_reader :harness_dir
    attr_reader :repo_dir

    # @arg params: a hash contaning the following
    #  config_location - the path to the ec-metal config.json including the filename.
    #    Optional, defaults to harness_dir/config.json
    #  harness_dir - The directory that ec-metal should save it's data to.
    #    Optional, defaults to the root ec-metal dir
    #  repo_dir - The directory that chef-repo should be written to.
    #    Optional, defaults to harness_dir/chef-repo
    #  cache_path - Where the cache should be written to.
    #    Optional, defaults to harness_dir/cache
    #  keypair_name - The name of the keypair used to create machines
    #    Optional for vagrant setups, but required for Ec2
    #  keypair_path - The path the keypair specified in keypair_name can be found.
    #    Optional, defaults to ~/.ssh for ec2 and is ignored for vagrant
    def initialize(params = {})
      @harness_dir = params[:harness_dir] || Pathname.new(File.dirname(__FILE__)).parent.to_s
      @config_location = params[:config_location] || File.join(@harness_dir, 'config.json')
      @repo_dir = params[:repo_dir] || File.join(@harness_dir, 'chef-repo')
      @cache_path = params[:cache_path]
      @keypair_name = params[:keypair_name]
      @keypair_path = params[:keypair_path] || "#{ENV['HOME']}/.ssh"

      # I'm open to having people explicitly call this as a setup function, but nothing is
      # likely to work if the config hasn't been written
      write_knife_config
    end

    def up
      create_users_directory
      ENV['HARNESS_DIR'] = @harness_dir
      ENV['REPO_PATH'] = @repo_dir
      run("bundle exec chef-client --config #{KNIFE} -z -o ec-harness::private_chef_ha",
          60*MINUTE_IN_DEC_SECS)
    end

    # Do all the basic env setup required for the up, upgrade, etc commands
    def setup
      keygen
      cachedir
      config_copy
      bundle
      berks_install
    end

    def config
      JSON.parse(File.read(@config_location))
    end

    # TODO(jmink) Make private once all main apis are in this file
    def create_users_directory
      FileUtils.mkdir_p(File.join(@harness_dir, 'users'))
    end

    def bundle
      run("bundle install --path vendor/bundle --binstubs", 3*MINUTE_IN_DEC_SECS)
    end

    private

    # These are all apis that are only called from within api, but could be exposed

    # Make a keys directory and ensure the correct keys are linked into it
    def keygen
      keydir = File.join(@repo_dir, 'keys')
      provider = EcMetal::ProviderSpecific.create_by_provider(config['provider'])
      provider.node_keys(keydir, @keypair_name, @keypair_path)
    end

    # Make a cachedir
    def cachedir
      if @cache_path && Dir.exists?(@cache_path)
        cachedir = @cache_path
      else
        cachedir = File.join(harness_dir, 'cache')
        FileUtils.mkdir_p cachedir
      end
      puts "Using package cache directory #{cachedir}"
    end

    # Copy an example config to harness_dir/config.json if no config is defined
    # TODO(jmink) In the longer term we should probably just throw an exception instead of coppying
    def config_copy
      unless @config_location && File.exists?(@config_location)
        config_file = File.join(harness_dir, 'config.json')
        config_ex_file = File.join(harness_dir, 'examples', 'config.json.example')
        unless File.exists?(config_file)
          FileUtils.cp(config_ex_file, config_file)
        end
      end
    end

    # Installs the Berksfile in the ec-metal repo
    def berks_install
      cookbooks_path = File.join(@repo_dir, 'vendor/cookbooks')
      # harness dir may be something other than the ec-metal dir, so we need to explicitly set it
      berks_file = Pathname.new(File.dirname(__FILE__)).parent.to_s + "/Berksfile"
      run("rm -r #{cookbooks_path}") if Dir.exists?(cookbooks_path)
      run("bundle exec berks vendor --berksfile='#{berks_file}' #{cookbooks_path}")
    end

    def write_knife_config
      ec_root = Pathname.new(File.dirname(__FILE__)).parent.to_s
      local_cookbooks = File.join(ec_root, 'cookbooks')
      ENV['LOCAL_COOKBOOKS'] = local_cookbooks

      keys_dir = File.join(@repo_dir, 'keys')

      FileUtils.mkdir_p(@repo_dir)
      FileUtils.mkdir_p(keys_dir)
      FileUtils.mkdir_p(File.join(ec_root, '.chef'))

      knife_location = File.join(ec_root, '.chef', 'knife.rb')
      KnifeConfig.write_knife_config(knife_location, @harness_dir, @repo_dir, keys_dir,
          @keypair_name, local_cookbooks)
    end


    # These are helper functions for api, which probably shouldn't ever be exposed

    # Shells out, ensures error messages are recorded and throws an exception on non-zero responses
    # timeout is in tenths of seconds (default 600 last checked)
    def run(command, timeout = nil)
      printable_env = ENV.to_a.map{|val| val.join('=')}.join(' ')
      puts "#{command} from #{harness_dir} with env #{printable_env}"

      shellout_params = {:env => ENV.to_hash}
      shellout_params[:timeout] = timeout unless timeout.nil?

      # TODO(jmink) determine why this env var needs to be set externally
      run = Mixlib::ShellOut.new("#{command}", shellout_params)
      run.run_command
      puts run.stdout
      puts "error messages for #{command}: #{run.stderr}" unless run.stderr.nil?
      run.error!
    end
  end
end
