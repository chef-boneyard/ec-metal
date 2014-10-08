require 'mixlib/config'
require 'ec_metal/config/server/settings'

module EcMetal
  class Config
    extend Mixlib::Config

    config_strict_mode true

    # currently only covers config.json settings
    # next, need to add harness and env vars

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
        default(:config) { EcMetal::Config.get_topology_configuration(type) } # send "get_topology_configuration_for_#{type}"
      end
    end

    config_context :addons do
      config_context :manage do
        default :version, 'release' # based on server version
        default(:fqdn) { build_hostname 'manage' }
        default :install?, true
        configurable :settings
      end

      config_context :push_jobs do
        default :version, 'release' # based on server version
        default :install?, false
        configurable :settings
      end

      config_context :reporting do
        default :version, 'release' # based on server version
        default :install?, false
        configurable :settings
      end
    end

    config_context :analytics do
      default(:fqdn) { build_hostname 'analytics' }
      configurable :settings
      config_context :topology do
        default :type, 'standalone'
      end
    end

  end
end

# {
#   "id": "ec-metal",
#   "provider": {
#     "type": "ec2",
#     "options": {
#       "region": "us-west-2",
#       "vpc_subnet": "subnet-5ac1133f",
#       "ami_id": "ami-09e27439",
#       "ssh_username": "ubuntu",
#       "keypair_name": "ec2_keyname"
#     }
#   },
#   "server": {
#     “version”: “12.0.0-rc.4-1”,
#     "apply_ec_bugfixes": false,
#     "run_pedant": true,
#     "package": "http://s3.amazonaws.com/...x86_64/private-chef_11.1.4-1_amd64.deb",
#     "settings": {
#       "api_fqdn": "api.precise.aws"
#     },
#     "topology": {
#       "type": "ha",
#       "backend_vip": {
#         "hostname": "backend.opscode.piab",
#         "ipaddress": "172.33.23.10",
#         "device": "eth0",
#         "heartbeat_device": "eth0"
#       },
#       "backends": {
#         "backend1.opscode.piab": {
#           "instance_type": "c3.xlarge",
#           "ebs_optimized": true,
#           "bootstrap": true
#         },
#         "backend2.opscode.piab": {
#           "instance_type": "c3.xlarge",
#           "ebs_optimized": true
#         }
#       },
#       "frontends": {
#         "frontend0.opscode.piab": {
#           "ebs_optimized": false,
#           "instance_type": "m3.medium"
#         }
#       }
#     }
#   },
#   "addons": {
#     "manage" : {
#       "package": "http://s3.amazonaws.com/...x86_64/opscode-manage_1.3.1-1_amd64.deb",
#       "fqdn": "manage65.centos.vagrant",
#       "settings": {
#       }
#     },
#     "push_jobs": {
#       "package": "http://s3.amazonaws.com/...x86_64/opscode-push-jobs-server_1.1.2-1_amd64.deb",
#       "settings": {
#         "command_port": 10002
#       }
#     },
#     "reporting": {
#       "package": "http://s3.amazonaws.com/...x86_64/opscode-reporting_1.1.5-1_amd64.deb"
#     }
#   },
#   "analytics": {
#     "package": "http://s3.amazonaws.com/...x86_64/opscode-analytics_1.0.0-1_amd64.deb",
#     “fqdn: “”,
#     “settings”: {
#       “”
#     }
#     “topology”: {
#       “type”: “standalone”
#     }
#   }
# }
