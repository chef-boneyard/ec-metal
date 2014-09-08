module EcMetal
  class ProviderSpecific

    require_relative 'ec2_specific'
    require_relative 'vagrant_specific'

    VAGRANT = 'vagrant'
    EC2 = 'ec2'

    def self.create_by_provider(provider)
      case provider
      when VAGRANT
        VagrantSpecific.new()
      when EC2
        Ec2Specific.new()
      end
    end
  end

  def node_keys(keydir)
    raise "Unimplemented.  Should be overridden in child class"
  end
end
