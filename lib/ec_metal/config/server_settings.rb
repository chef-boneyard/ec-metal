require 'mixlib/config'

module EcMetal
  class ServerSettingsConfig
    extend Mixlib::Config

    default(:api_fqdn) { EcMetal::Config.build_hostname 'api' }
  end
end
