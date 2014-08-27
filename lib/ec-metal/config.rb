require 'mixlib/config'
module ECMetal
  class Config
    extend Mixlib::Config
    config_strict_mode true

    ## Host setup
    # Path to the ec-metal directory
    default(:harness_dir) { ENV['HARNESS_DIR'] || File.absolute_path(File.join(File.dirname(__FILE__), '..', '..')) }

    # Path where chef-zero sets up shop
    default(:repo_path)  { ENV['REPO_PATH'] || File.join(harness_dir, 'chef-repo') }

    # Path to cache holding chef-server packages
    default(:cache_dir)  { ENV['ECM_CACHE_PATH'] || File.join(harness_dir, 'cache') }

    # Path to directory holding vagrant vms
    default(:vms_dir)    { File.join(harness_dir, 'vagrant_vms') }

    # Path to ssh keys
    default(:keys_dir)   { File.join(repo_path, 'keys') }

    ## Layout and Topo
    # This file contains the various config for the tests
    default(:test_config) { ENV['ECM_CONFIG'] || 'config.json' }

    # chef-server package to deploy
    default(:target_package) { ENV['ECM_TARGET_PACKAGE_NAME'] }

    # manage pacakge to deploy
    default(:manage_package) { ENV['ECM_DEPENDENT_PACKAGE_NAME'] }

    # default-orgname
    default(:default_orgname) { ENV['ECM_DEFAULT_ORGNAME'] }

    # Run pedant after setting up tests?
    default(:run_pedant)  { !(ENV['ECM_RUN_PEDANT'].nil? || ENV['ECM_RUN_PEDANT'].empty?) }

    # Keypair name
    default(:keypair_name) { ENV['ECM_KEYPAIR_NAME'] || "#{ENV['USER']}@#{::File.basename(harness_dir)}" }

    def self.to_hash
      {
        'harness_dir' => harness_dir,
        'repo_path'   => repo_path,
        'host_cache_dir' => cache_dir,
        'vms_dir'     => vms_dir,
        'keys_dir'    => keys_dir,
        'package_name' => target_package,
        'default_orgname' => default_orgname,
        'keypair_name' => keypair_name,
        'run_pedant' => run_pedant,
        'manage_package' => manage_package
      }

    end

  end
end
