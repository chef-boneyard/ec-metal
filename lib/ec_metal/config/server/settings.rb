require 'mixlib/config'

module EcMetal
  class ServerSettings
    extend Mixlib::Config

    config_strict_mode true

    default(:api_fqdn) { EcMetal::Config.build_hostname 'api' }
  end
end
