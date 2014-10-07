require 'mixlib/config'

require 'ec_metal/config/core'
require 'ec_metal/config/server_settings'
require 'ec_metal/config/provider_options_ec2'

module EcMetal
  module Config
    module Helper
      
      def self.build_hostname(hostname)
        "#{hostname}.#{EcMetal::Config::Core.server.base_hostname}"
      end

      def self.get_provider_options(type)
        case type
        when 'ec2'
            EcMetal::Config::ProviderOptionsEc2
        else
          raise "Can not assign options to #{type} provider"
        end
      end

    end
  end
end