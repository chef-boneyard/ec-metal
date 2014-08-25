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
    default :keypair_name, ENV['ECM_KEYPAIR_NAME']

  end
end
