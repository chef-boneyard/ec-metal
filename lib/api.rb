require "mixlib/shellout"
require 'pathname'

module EcMetal
  class Api
    def self.up
      create_users_directory
      run("#{harness_dir}/bin/chef-client -z -o ec-harness::private_chef_ha")
    end

    # TODO(jmink) Make private once all main apis are in this file
    # Also look through and determine what else should be made private
    def self.create_users_directory
      FileUtils.mkdir_p(File.join(ENV['HARNESS_DIR'], 'users'))
    end

    # Do all the basic env setup required for the up, upgrade, etc commands
    def self.setup
      print_enviornment
      keygen
      cachedir
      config_copy
      bundle
      berks_install
    end

    def self.print_enviornment
      puts "================== ec-metal ENV ==========================="
      ENV.each { |k,v| puts "#{k} = #{v}" if k.include?("ECM_") }
      puts "==========================================================="
    end

    def self.keygen
      keydir = File.join(repo_dir, 'keys')
      FileUtils.mkdir_p keydir

      if Dir["#{keydir}/*"].empty? && !ENV['ECM_KEYPAIR_PATH'].nil?
        FileUtils.copy("#{ENV['ECM_KEYPAIR_PATH']}/id_rsa", "#{keydir}/id_rsa")
        FileUtils.copy("#{keydir}/id_rsa", "#{keydir}/#{ENV['ECM_KEYPAIR_NAME']}") unless ENV['ECM_KEYPAIR_NAME'].nil?
        FileUtils.copy("#{ENV['ECM_KEYPAIR_PATH']}/id_rsa.pub", "#{keydir}/id_rsa.pub")
      end

      if Dir["#{keydir}/*"].empty?
        comment = ENV['ECM_KEYPAIR_NAME'].nil? ? "" : "-C #{ENV['ECM_KEYPAIR_NAME']}"
        run("ssh-keygen #{comment} -P '' -q -f #{keydir}/id_rsa")
      end
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
      run("rm -r #{cookbooks_path}") if Dir.exists?(cookbooks_path)
      run("#{harness_dir}/bin/berks vendor #{cookbooks_path}")
    end

    def self.bundle
      run('bundle install --path vendor/bundle --binstubs')
    end

    # Environment variables to be consumed by ec-harness and friends
    def self.harness_dir
      harness_dir = ENV['HARNESS_DIR'] ||= Pathname.new(File.dirname(__FILE__)).parent.to_s
    end

    def self.repo_dir
      repo_dir = ENV['REPO_PATH'] ||= File.join(harness_dir, 'chef-repo')
    end


    private

    # Shells out, ensures error messages are recorded and throws an exception on non-zero responses
    def self.run(command)
      puts command
      run = Mixlib::ShellOut.new(command, :cwd => harness_dir)
      run.run_command
      puts "error messages for #{command}: #{run.stderr}" unless run.stderr.nil?
      run.error!
    end
  end
end
