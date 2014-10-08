require 'mixlib/config'

module EcMetal
  class VagrantProviderOptions
    extend Mixlib::Config

    config_strict_mode true

    default :vagrant_provider, 'virtualbox'

  end
end
