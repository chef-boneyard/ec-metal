require 'mixlib/config'

module EcMetal
  class StandaloneTopologyConfiguration
    extend Mixlib::Config

    config_strict_mode true

    default :backend_servers, 0
    default :frontend_servers, 0
  end
end
