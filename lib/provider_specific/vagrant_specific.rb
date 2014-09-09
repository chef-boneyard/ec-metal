require_relative 'provider_specific'

module EcMetal
  class VagrantSpecific < ProviderSpecific
    # Links to existing keys or raises an exception
    # keypair name is either <name>.pem or id_rsa
    def node_keys(keydir, keypair_name, keypair_path)
      FileUtils.mkdir_p keydir

      if Dir["#{keydir}/*"].empty?
        comment = keypair_name.nil? ? "" : "-C #{keypair_name}"
        run("ssh-keygen #{comment} -P '' -q -f #{keydir}/id_rsa")
      end
    end

  end
end
