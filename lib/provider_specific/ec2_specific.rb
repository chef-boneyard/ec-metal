require_relative 'provider_specific'

module EcMetal
  class Ec2Specific < ProviderSpecific
    # Creates the keys needed to create the vagrant nodes.  Don't bother recreating if keys already exist
    def node_keys(keydir)
      if ENV['ECM_KEYPAIR_NAME'].nil?
        raise "ECM_KEYPAIR_NAME must be set for EC2 runs. ECM_KEYPAIR_PATH defaults to ~/.ssh"
      end

      keypair_path = ENV['ECM_KEYPAIR_PATH'] || '~/.ssh'

      FileUtils.mkdir_p keydir
      if Dir["#{keydir}/*"].empty?
        private_key, public_key = normalize_keypair_name(ENV['ECM_KEYPAIR_NAME'])
        FileUtils.ln_s("#{keypair_path}/#{private_key}", "#{keydir}/id_rsa")
        FileUtils.ln_s("#{keypair_path}/#{public_key}", "#{keydir}/id_rsa.pub")
      end
    end

    private

    # @returns public_key_name, private_key_name
    def normalize_keypair_name(keypair_name)
      if keypair_name == 'id_rsa'
        return ['id_rsa', 'id_rsa.pub']
      end

      base_name = keypair_name.gsub('\.pem', '')
      ["#{base_name}.pem", "#{base_name}.pub"]
    end

  end
end
