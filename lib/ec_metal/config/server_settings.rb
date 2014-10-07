require 'ec_metal/config'

module EcMetal
  module Config
    class ServerSettings
      extend Mixlib::Config

      default(:api_fqdn) { EcMetal::Config::Helper.build_hostname 'api' }
    end
  end
end
