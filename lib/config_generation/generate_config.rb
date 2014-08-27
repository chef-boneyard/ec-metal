# This is a base class that's inherited from by other classes in the directory
# It creates a config file for ec-metal to consume and is driven by the 'generate_config' rake task
# It's behavior is modified by several env vars


module EcMetal
  class GenerateConfig

    require_relative 'generate_ec2_config'
    require_relative 'generate_vagrant_config'

    VALID_TOPOS = ['ha', 'standalone', 'tier']
    VALID_VARIANTS = ['private_chef', 'chef_server']
    VALID_PROVIDERS = ['vagrant', 'ec2']

    def self.create_by_provider(provider, args, filename)
      case provider
      when 'vagrant'
        EcMetal::GenerateVagrantConfig.new(args, filename)
      when 'ec2'
        EcMetal::GenerateEc2Config.new(args, filename)
      end
    end

    def initialize(args, file_name)
      validate_arguments(args)
      @options = args
      @config = {}
      modify_config()
      # TODO(jmink) Error handling?
      File.open(file_name, 'w') do |file|
        file.write JSON.pretty_generate @config
      end
    end

    def validate_arguments(args)
      if args.topology.nil? || args.variant.nil? || args.platform.nil? || args.provider.nil?
        raise("ERROR: All arguments required")
      end

      unless VALID_PROVIDERS.include? args.provider
        raise("ERROR: #{args.provider} not recognized.  Valid providers are #{VALID_PROVIDERS.join(', ')}")
      end

      unless VALID_TOPOS.include? args.topology
        raise("ERROR: #{args.topology} not recognized.  Valid topos are #{VALID_TOPOS.join(', ')}")
      end

      unless VALID_VARIANTS.include? args.variant
        raise("ERROR: #{args.variant} not recognized.  Valid variants are #{VALID_VARIANTS.join(', ')}")
      end
    end


    def modify_config()
      @config['provider'] = @options.provider
      set_provider_data()

      # TODO(jmink) handle upgrade packages correctly
      # TODO(jmink) Error handling
      @config["default_package"] = ENV['ECM_TARGET_PACKAGE_NAME']
      @config["manage_package"] = ENV['ECM_DEPENDENT_PACKAGE_NAME'] unless ENV['ECM_DEPENDENT_PACKAGE_NAME'].nil?
      @config['run_pedant'] = !(ENV['ECM_RUN_PEDANT'].nil? || ENV['ECM_RUN_PEDANT'].empty?)

      @config[:packages] = {}
      set_topology()

      # TODO(jmink) Deal with any weird open source bits & ensure upgrade is set up correctly
    end

    # default_orgname mode allows you to set an OSC-compatible by designating one org as
    # the default org. This setting enables default_org on the chef-server brought up by
    # ec-metal. If run_pedant is true, it will also run a second Pedant test in default-org
    # mode to test out those routes.
    def default_orgname
      ENV['ECM_DEFAULT_ORGNAME']
    end

    def set_provider_data()
      raise "Unimplemented.  Should be overwritten in child class"
    end

    def set_topology()
      @config[:layout] = { :topology => @options.topology }
      case @options.topology
      when 'ha'
        generate_full_topology(:num_backends => 2, :num_frontends => 1)
      when 'standalone'
        # TOOD(jmink)
        generate_standalone_topology()
      when 'tier'
        generate_full_topology(:num_backends => 1, :num_frontends => 1)
      end
    end

    # adding this just to get something end to end in CI
    def generate_standalone_topology()
      name = 'pwcsta'
      # Define provider agnostic layout
      @config[:layout] = { :topology => @options.topology,
        :api_fqdn => 'api.opscode.aws',
        :default_orgname => default_orgname,
        :manage_fqdn => 'manage.opscode.aws',
        :analytics_fqdn => 'analytics.opscode.aws',
        :standalones => {
          "#{name}-standalone" => {
            :hostname => "#{name}-standalone.centos.aws",
            :ebs_optimized => true,
            :instance_type => 'm3.xlarge'
          }
        }
      }
    end

    # Differences between HA & tiered:
    # HA has a seperate backend VIP
    # Tiered has a backend VIP section, which just points to the single backend
    # Standalone has no backend VIP section
    def generate_full_topology(options)
      @config[:layout] = { :topology => @options.topology,
        :api_fqdn => 'api.opscode.piab',
        :default_orgname => default_orgname,
        :manage_fqdn => 'manage.opscode.piab',
        :analytics_fqdn => 'analytics.opscode.piab',
        :backends => {},
        :frontends => {}
        }

    # @returns a string which represents the backend vip device
    def backend_vip_device
      raise "Unimplemented.  Should be overwritten in child class"
    end

    # @returns a string which represents the backend vip heartbeat device
    def backend_vip_heartbeat_device
      raise "Unimplemented.  Should be overwritten in child class"
    end

    # @returns a hash which represents the nth backend
    def generate_backend(n)
      raise "Unimplemented.  Should be overwritten in child class"
    end

    # @returns a hash which represents the nth frontend
    def generate_frontend(n)
      raise "Unimplemented.  Should be overwritten in child class"
    end

    # modifies @config in any way required for that specific provider
    def provider_specific_config_modification()
      raise "Unimplemented.  Should be overwritten in child class"
    end
  end
end
