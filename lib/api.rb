require_relative 'provider_specific/provider_specific.rb'

require "mixlib/shellout"
require 'pathname'
# require 'bundler'

module EcMetal
  class Api

    MINIMUM_CHEFDK_VERSION = '0.5.0.rc.4'

    MINUTE_IN_DEC_SECS = 600
    KNIFE = File.join(File.dirname(File.dirname(__FILE__)), '.chef', 'knife.rb')

    # Executes chef-client with the recipe that creates a chef server. Optionally consumes subcommands
    # from the "rake up" task --log_level for verbose output
    def self.up(log_level=nil)
      create_users_directory
      ENV['HARNESS_DIR'] = harness_dir
      ENV['ECM_CHEF_REPO'] = repo_dir

      # Optionally pass "debug" argument from the "rake up" task to the chef-client run
      chef_client_command = "chef-client --config #{KNIFE} -z -o ec-harness::default --force-formatter"

      if log_level
        chef_client_command += " -l #{log_level}"
        puts "Setting chef-client log_level to #{log_level}"
      end

      run(chef_client_command, 60*MINUTE_IN_DEC_SECS)
    end

    def self.destroy
      ENV['HARNESS_DIR'] = harness_dir
      ENV['ECM_CHEF_REPO'] = repo_dir
      run("chef-client --config #{KNIFE} -z -o ec-harness::cleanup --force-formatter")
    end

    def self.config
      JSON.parse(File.read(ENV['ECM_CONFIG'] || "#{harness_dir}/config.json"))
    end

    # TODO(jmink) Make private once all main apis are in this file
    # Also look through and determine what else should be made private
    def self.create_users_directory
      FileUtils.mkdir_p(File.join(harness_dir, 'users'))
    end

    # Do all the basic env setup required for the up, upgrade, etc commands
    def self.setup
      check_chefdk
      cleanup_bundler
      print_enviornment
      keygen
      cachedir
      config_copy
      berks_install
    end

    def self.check_chefdk
      printf 'Checking your ChefDK... '
      # output like: Chef Development Kit Version: 0.4.0
      chefdk_version = `chef --version`.lines.first.split(':')[1].chomp
      unless Gem::Version.new(chefdk_version) >= Gem::Version.new(MINIMUM_CHEFDK_VERSION)
        raise "Your ChefDK version #{chefdk_version} is less than the required version #{MINIMUM_CHEFDK_VERSION}"
      end
      puts 'OK'
    rescue
      raise 'Error detecting ChefDK.  Please install ChefDK and set it as your system Ruby before proceeding: https://docs.chef.io/install_dk.html'
    end

    def self.cleanup_bundler
      if Dir.entries(harness_dir).include?('Gemfile.lock')
        puts 'Cleaning up your artisanally crafted bundled gems, please re-run the rake task to continue'
        File.delete(File.join(harness_dir, 'Gemfile.lock'))
        exit 1
      end
      if Dir.entries(harness_dir).include?('vendor') &&
        Dir.entries(File.join(harness_dir, 'vendor')).include?('bundle')
        puts "WARNING: bundle directory detected at #{File.join(harness_dir, 'vendor', 'bundle')}. It is now safe to completely remove it"
      end
    end

    def self.print_enviornment
      puts "================== ec-metal ENV ==========================="
      ENV.each { |k,v| puts "#{k} = #{v}" if k.include?("ECM_") }
      puts "==========================================================="
    end

    def self.keygen
      keydir = File.join(repo_dir, 'keys')
      EcMetal::ProviderSpecific.create_by_provider(config['provider']).node_keys(keydir)
    end

    def self.cachedir
      if ENV['ECM_CACHE_PATH'] && Dir.exists?(ENV['ECM_CACHE_PATH'])
        cachedir = ENV['ECM_CACHE_PATH']
      else
        cachedir = File.join(harness_dir, 'cache')
        FileUtils.mkdir_p cachedir
      end
      puts "Using package cache directory #{cachedir}"
    end

    def self.config_copy
      unless ENV['ECM_CONFIG'] && File.exists?(ENV['ECM_CONFIG'])
        config_file = File.join(harness_dir, 'config.json')
        config_ex_file = File.join(harness_dir, 'examples', 'config.json.example')
        unless File.exists?(config_file)
          FileUtils.cp(config_ex_file, config_file)
        end
      end
    end

    def self.berks_install
      cookbooks_path = File.join(repo_dir, 'vendor/cookbooks')
      # harness dir may be something other than the ec-metal dir, so we need to explicitly set it
      berks_file = Pathname.new(File.dirname(__FILE__)).parent.to_s + "/Berksfile"
      run("rm -r #{cookbooks_path}") if Dir.exists?(cookbooks_path)
      run("berks vendor -q --berksfile='#{berks_file}' #{cookbooks_path}")
    end

    def self.berks_update
      berks_file = Pathname.new(File.dirname(__FILE__)).parent.to_s + "/Berksfile"
      run("berks update --berksfile='#{berks_file}'")
    end

    # Only run this for ec-metal without wrappers
    # def self.bundle
    #   run("bundle install --path vendor/bundle --binstubs", 3*MINUTE_IN_DEC_SECS)
    # end

    # Environment variables to be consumed by ec-harness and friends
    def self.harness_dir
      harness_dir = ENV['HARNESS_DIR'] ||= Pathname.new(File.dirname(__FILE__)).parent.to_s
    end

    def self.repo_dir
      repo_dir = ENV['ECM_CHEF_REPO'] ||= File.join(harness_dir, 'chef-repo')
    end


    # TODO(jmink) Move this into a utils class
    # Shells out, ensures error messages are recorded and throws an exception on non-zero responses
    # timeout is in tenths of seconds (default 600 last checked)
    def self.run(command, timeout = nil)
      STDOUT.sync = true

      printable_env = ENV.to_a.map{|val| val.join('=')}.join(' ')
      puts "#{command} from #{harness_dir}"

      shellout_params = {:env => ENV.to_hash, :cwd => harness_dir, :live_stream => STDOUT}
      shellout_params[:timeout] = timeout unless timeout.nil?

      # TODO(jmink) determine why this env var needs to be set externally
      run = Mixlib::ShellOut.new("BERKSHELF_CHEF_CONFIG=$PWD/berks_config #{command}", shellout_params)
      run.run_command
      # puts run.stdout
      # puts "error messages for #{command}: #{run.stderr}" unless run.stderr.nil?
      # run.error!
    end
  end
end
