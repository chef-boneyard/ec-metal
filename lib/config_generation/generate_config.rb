# This is a base class that's inherited from by other classes in the directory
# It creates a config file for ec-metal to consume and is driven by the 'generate_config' rake task
# It's behavior is modified by several env vars

module EcMetal
  class GenerateConfig

    def self.create(filename)
      case ECMetal::Config.provider
      when 'vagrant'
        EcMetal::GenerateVagrantConfig.new(filename)
      when 'ec2'
        EcMetal::GenerateEc2Config.new(filename)
      end
    end

    def initialize(file_name)
      ECMetal::Config.validate!
      @config = ECMetal::Config.to_hash
      modify_config()
      # TODO(jmink) Error handling?
      File.open(file_name, 'w') do |file|
        file.write JSON.pretty_generate @config
      end
    end

    def set_provider_data()
      raise "Unimplemented.  Should be overwritten in child class"
    end

    def modify_config()
      set_provider_data()

      @config[:packages] = {}
      set_topology()

      # TODO(jmink) Deal with any weird open source bits & ensure upgrade is set up correctly
    end

    def set_provider_data()
      raise "Unimplemented.  Should be overwritten in child class"
    end


    def set_topology()
      @config[:layout] = { :topology => ECMetal::Config.topology }
      case ECMetal::Config.topology
      when 'ha'
        generate_full_topology(:num_backends => 2, :num_frontends => 1)
      when 'standalone'
        generate_standalone_topology()
      when 'tier'
        generate_full_topology(:num_backends => 1, :num_frontends => 1)
      end
    end
    #
    # adding this just to get something end to end in CI
    def generate_standalone_topology()
      # Define provider agnostic layout
      @config[:layout] = { :topology => ECMetal::Config.topology,
                           :api_fqdn => 'api.opscode.piab',
                           :default_orgname => ECMetal::Config.default_orgname,
                           :manage_fqdn => 'manage.opscode.piab',
                           :analytics_fqdn => 'analytics.opscode.piab',
                           :standalones => { "api.opscode.piab" => generate_standalone }
      }
    end

    # Differences between HA & tiered:
    # HA has a seperate backend VIP
    # Tiered has a backend VIP section, which just points to the single backend
    # Standalone has no backend VIP section
    def generate_full_topology(options)
      @config[:layout] = { :topology => ECMetal::Config.topology,
                           :api_fqdn => 'api.opscode.piab',
                           :default_orgname => ECMetal::Config.default_orgname,
                           :manage_fqdn => 'manage.opscode.piab',
                           :analytics_fqdn => 'analytics.opscode.piab',
                           :backends => {},
                           :frontends => {}
      }

      options[:num_backends].times do |n|
        backend = generate_backend(n)
        backend[:bootstrap] = true if n == 0
        @config[:layout][:backends]["backend#{n}"] = backend
      end
      options[:num_frontends].times do |n|
        @config[:layout][:frontends]["frontend#{n}"] = generate_frontend(n)
      end

      if options[:num_backends] > 1
        vip = { :hostname => "backend.opscode.piab",
                :ipaddress => "33.33.33.20" }
      else
        backend_name = @config[:layout][:backends].keys.first
        vip = @config[:layout][:backends][backend_name]
      end

      @config[:layout][:backend_vip] = {
        :hostname => vip[:hostname],
        :ipaddress => vip[:ipaddress],
        # TODO(jmink) figure out a smarter way to determine devices
        :device => "eth0",
        :heartbeat_device => "eth1"
      }

      provider_specific_config_modification()
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
