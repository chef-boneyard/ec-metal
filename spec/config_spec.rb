require 'spec_helper'
require 'config'

describe EcMetal::Config do
  context "provider type and options" do
    it "default to ec2 with ec2 options" do
      expect(EcMetal::Config.provider.type).to eq('ec2')
      expect(EcMetal::Config.provider.region).to eq('us-west-2')
      expect(EcMetal::Config.provider.vpc_subnet).to eq('subnet-5ac1133f')
      expect(EcMetal::Config.provider.ami).to eq('ami-09e27439')
      expect(EcMetal::Config.provider.ssh_username).to eq('ubuntu')
      expect(EcMetal::Config.provider.keypair_name).to eq(nil)
    end

    it "configurable keypair_name" do
      EcMetal::Config.provider.keypair_name = 'testkey'
      expect(EcMetal::Config.provider.keypair_name).to eq('testkey')
    end
  end

  context "#build_hostname" do
    it "returns generated hostname with default base hostname" do
      expect(EcMetal::Config.build_hostname('built')).to eq('built.opscode.piab')
    end

    it "returns generated hostname with overridden base hostname" do
      EcMetal::Config.server.base_hostname = 'getchef.com'
      expect(EcMetal::Config.build_hostname('built')).to eq('built.getchef.com')
    end
  end
end
