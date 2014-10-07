require 'ec_metal/config'

module EcMetal
  module Config
    class ProviderOptionsEc2
      extend Mixlib::Config

      config_strict_mode true

      default :region, 'us-west-2'
      default :vpc_subnet, 'subnet-5ac1133f'
      default :ami, 'ami-09e27439' # ubuntu, version?
      default :ssh_username, 'ubuntu' # we can actually derive this from the ami
      configurable :keypair_name
    end
  end
end

