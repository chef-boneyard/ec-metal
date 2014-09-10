require_relative 'provider_specific'
require_relative '../api.rb'

module EcMetal
  class VagrantSpecific < ProviderSpecific
    # Links to existing keys or raises an exception
    # keypair name is either <name>.pem or id_rsa
    def node_keys(keydir)
      FileUtils.mkdir_p keydir

      if Dir["#{keydir}/*"].empty?
        comment = ENV['ECM_KEYPAIR_NAME'].nil? ? "" : "-C #{ENV['ECM_KEYPAIR_NAME']}"
        Api.run("ssh-keygen #{comment} -P '' -q -f #{keydir}/id_rsa")
      end
    end

  end
end
