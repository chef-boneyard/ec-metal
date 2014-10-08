require 'mixlib/config'
require 'ec_metal/config/server/settings'

module EcMetal
  class Config
    extend Mixlib::Config

    config_strict_mode true

    def self.build_hostname(hostname)
      "#{hostname}.#{EcMetal::Config.server.base_hostname}"
    end

    def self.get_provider_options(type)
      case type
      when 'ec2'
        require 'ec_metal/config/provider/ec2_options'
        EcMetal::Ec2ProviderOptions
      else
        raise "Can not assign options to #{type} provider"
      end
    end

    def self.get_topology_configuration(type)
      case type
      when 'standalone'
        require 'ec_metal/config/server/topology/standalone'
        EcMetal::StandaloneTopologyConfiguration
      else
        raise "Can not assign configuration to #{type} topology"
      end
    end

    default :harness_dir, Pathname.new(File.dirname(__FILE__)).parent.parent.to_s # seriously, there has got to be a better way to identify the harness dir

    default :chef_repo_dir, File.join(harness_dir, 'chef-repo')

    configurable :config_file # This file will now be overrides... also need to reconsider if this should be json

    default(:package_cache_dir) { File.join(chef_repo_dir, 'cache') }

    configurable :keypair_dir

    config_context :provider do
      default :type, 'ec2'
      default(:options) { EcMetal::Config.get_provider_options(type) } # send "get_provider_options_for_#{type}"
    end

    config_context :server do
      default :version, 'latest' # keyword
      default :apply_ec_bugfixes, false
      default :run_pedant, true
      configurable :package # url or local path
      default :base_hostname, 'opscode.piab'

      config_context :settings do
        default(:api_fqdn) { EcMetal::ServerSettings.api_fqdn }
      end

      config_context :topology do
        default :type, 'standalone'
        # Topology specfic configurations will be managed by recipes.
        # We'll see what additional config is required as we build those out.
        # default(:config) { EcMetal::Config.get_topology_configuration(type) } # send "get_topology_configuration_for_#{type}"
      end
    end

    config_context :addon do
      config_context :manage do
        default :version, 'release' # based on server version
        default(:fqdn) { EcMetal::Config.build_hostname('manage') }
        configurable :settings
        configurable :package # url or local path
      end

      config_context :push_jobs do
        default :version, 'release' # based on server version
        configurable :settings
        configurable :package # url or local path
      end

      config_context :reporting do
        default :version, 'release' # based on server version
        configurable :settings
        configurable :package # url or local path
      end
    end

    config_context :analytics do
      default :version, 'release' # based on server version
      configurable :package # url or local path
      default(:fqdn) { EcMetal::Config.build_hostname('analytics') }
      configurable :settings
      config_context :topology do
        default :type, 'standalone'
      end
    end

  end
end
