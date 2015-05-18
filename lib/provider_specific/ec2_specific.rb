require_relative 'provider_specific'

module EcMetal
  class Ec2Specific < ProviderSpecific
    # Creates the keys needed to create the vagrant nodes.  Don't bother recreating if keys already exist
    def node_keys(keydir)
      FileUtils.mkdir_p keydir

      if ENV['ECM_KEYPAIR_PATH']
        keypair_path = ENV['ECM_KEYPAIR_PATH']

        if Dir["#{keydir}/*"].empty?
          private_key, public_key = normalize_keypair_name(ENV['ECM_KEYPAIR_NAME'])
          # If you followed the instructions and made your ssh key like "irving@ec-metal.pem"
          if File.exist?(File.join(keypair_path, private_key))
            FileUtils.ln_s("#{keypair_path}/#{private_key}", "#{keydir}/id_rsa")
            FileUtils.ln_s("#{keypair_path}/#{private_key}", "#{keydir}/#{private_key}")
            FileUtils.ln_s("#{keypair_path}/#{public_key}", "#{keydir}/id_rsa.pub")
          # if you set up an ECM_KEYPAIR_PATH, but your ssh key is named "id_rsa"
          elsif File.exist?(File.join(keypair_path, 'id_rsa'))
            FileUtils.ln_s("#{keypair_path}/id_rsa", "#{keydir}/id_rsa")
            FileUtils.ln_s("#{keypair_path}/id_rsa", "#{keydir}/#{private_key}")
            FileUtils.ln_s("#{keypair_path}/id_rsa.pub", "#{keydir}/id_rsa.pub")
          else
            raise "ERROR: You set an $ECM_KEYPAIR_PATH of #{keypair_path} but didn't put any ssh keys in there!"
          end
        end
      else
        # Legacy mode, like the old, simple days
        if Dir["#{keydir}/*"].empty?
          comment = ENV['ECM_KEYPAIR_NAME'].nil? ? "" : "-C #{ENV['ECM_KEYPAIR_NAME']}"
          Api.run("ssh-keygen #{comment} -P '' -q -f #{keydir}/id_rsa")

          private_key, public_key = normalize_keypair_name(ENV['ECM_KEYPAIR_NAME'])
          FileUtils.ln_s("#{keydir}/id_rsa", "#{keydir}/#{private_key}")
        end
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
