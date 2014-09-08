require_relative 'provider_specific'

module EcMetal
  class Ec2Specific < ProviderSpecific
    # Creates the keys needed to create the vagrant nodes.  Don't bother recreating if keys already exist
    def node_keys(keydir)
      if ENV['ECM_KEYPAIR_PATH'].nil? || ENV['ECM_KEYPAIR_NAME'].nil?
        raise "Keypair path and name must be set for EC2 runs (ECM_KEYPAIR_PATH, ECM_KEYPAIR_NAME)"
      end

      FileUtils.mkdir_p keydir
      if Dir["#{keydir}/*"].empty?
        private_key, public_key = normalize_keypair_name(ENV['ECM_KEYPAIR_NAME'])
        FileUtils.ln_s("#{ENV['ECM_KEYPAIR_PATH']}/#{private_key}", "#{keydir}/#{private_key}")
        FileUtils.ln_s("#{ENV['ECM_KEYPAIR_PATH']}/#{public_key}", "#{keydir}/#{public_key}")
      end
    end

    private

    # @returns public_key_name, private_key_name
    def normalize_keypair_name(keypair_name)
      if keypair_name != 'id_rsa'
        return ['id_rsa', 'id_rsa.pub']
      end

      base_name = keypair_name.gsub('\.pem', '')
      ["#{base_name}.pem", "#{base_name}.pub"]
    end

  end
end
