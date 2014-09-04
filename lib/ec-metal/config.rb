require 'mixlib/config'
module ECMetal
  class Config
    VALID_TOPOS = ['ha', 'standalone', 'tier']
    VALID_VARIANTS = ['private_chef', 'chef_server']
    VALID_PROVIDERS = ['vagrant', 'ec2']
    EXPORT_KEYS = %w(
      harness_dir repo_path host_cache_dir vms_dir keys_dir
      provider default_package manage_package default_orgname run_pedant )

    extend Mixlib::Config
    config_strict_mode true

    ## Host setup
    # Path to the ec-metal directory
    default(:harness_dir) { File.absolute_path(File.join(File.dirname(__FILE__), '..', '..')) }

    # Path where chef-zero sets up shop
    default(:repo_path)  { File.join(harness_dir, 'chef-repo') }

    # Path to cache holding chef-server packages
    default(:host_cache_dir)  { File.join(harness_dir, 'cache') }

    # Path to directory holding vagrant vms
    default(:vms_dir)    { File.join(harness_dir, 'vagrant_vms') }

    # Path to ssh keys
    default(:keys_dir)   { File.join(repo_path, 'keys') }

    ## Layout and Topo
    # Sets the provider (vagrant or EC)
    default :provider, 'vagrant'

    # Sets the topology
    default :topology, 'standalone'

    # Sets the chef-server variant
    default :variant, 'private_chef'

    # Sets the platform
    default :platform, 'ubuntu-12.04'

    # This file contains the various config for the tests
    default(:config_file) { 'config.json' }

    # chef-server package to deploy
    configurable :default_package

    # manage pacakge to deploy
    configurable :manage_package

    # default-orgname
    configurable :default_orgname

    # Run pedant after setting up tests?
    default :run_pedant, false

    # Keypair name
    default(:keypair_name) { "#{ENV['USER']}@#{::File.basename(harness_dir)}" }

    # Keypair path
    configurable :keypair_path

    def self.to_hash
      config_values = EXPORT_KEYS.
        map { |x| [x, self.send(x)] }.
        reject { |(k,v)| v.nil? }
      Hash[config_values]
    end

    # Loads config from file and merge in overrides from ENV values
    def self.generate_data_bag_item(config)
      json_config = JSON.parse(File.read(config))
      from_hash(json_config)
      from_env
      json_config.merge(self.to_hash)
    end

    # Instead of annotating a config, this function
    # loads an exissting config.json file and merges
    # settings from ENV
    def self.write_data_bag_item(filename)
      File.open(filename, 'w') do |file|
        file.write JSON.pretty_generate(generate_data_bag_item(config_file))
      end
    end

    # Loads config values from a hash, but only ones for which
    # keys are defined here.
    def self.from_hash(hash)
      self.restore(Hash[hash.to_a.select { |(k,v)| self.has_key?(k) }])
    end

    def self.from_json_file(filename)
      self.from_hash(JSON.parse(File.read(filename)))
    end

    # We have a separate way of loading in ENV. This way, we can load values from
    # file, and then load values from ENV
    def self.from_env
      env = [
        ['harness_dir', ENV['HARNESS_DIR']],
        ['repo_path', ENV['REPO_PATH']],
        ['cache_dir', ENV['ECM_CACHE_PATH']],
        ['config_file', ENV['ECM_CONFIG']],
        ['default_package', ENV['ECM_TARGET_PACKAGE_NAME']],
        ['manage_package', ENV['ECM_DEPENDENT_PACKAGE_NAME']],
        ['default_orgname', ENV['ECM_DEFAULT_ORGNAME']],
        ['run_pedant', (ENV['ECM_RUN_PEDANT'].nil? || ENV['ECM_RUN_PEDANT'].empty? ? nil : true)],
        ['keypair_name', ENV['ECM_KEYPAIR_NAME']]
      ].
        reject { |(k,v)| v.nil? || (v.respond_to?(:empty?) && v.empty?) }.
        each   { |(k,v)| self.send(k, v) } # For some reason, merge!() does not work
    end

    def self.validate!
      if topology.nil? || variant.nil? || platform.nil? || provider.nil?
        raise("ERROR: topology, variant, platform, and provider required")
      end

      unless VALID_PROVIDERS.include? provider
        raise("ERROR: #{provider} not recognized.  Valid providers are #{VALID_PROVIDERS.join(', ')}")
      end

      unless VALID_TOPOS.include? topology
        raise("ERROR: #{topology} not recognized.  Valid topos are #{VALID_TOPOS.join(', ')}")
      end

      unless VALID_VARIANTS.include? variant
        raise("ERROR: #{variant} not recognized.  Valid variants are #{VALID_VARIANTS.join(', ')}")
      end
    end

  end
end
