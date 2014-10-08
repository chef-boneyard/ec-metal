require 'spec_helper'
require 'ec_metal/config'

describe EcMetal::Config do
  before(:each) do
    EcMetal::Config.reset
  end

  context "provider type and options" do
    it "default to ec2 with ec2 options" do
      expect(EcMetal::Config.provider.type).to eq('ec2')
      expect(EcMetal::Config.provider.options.region).to eq('us-west-2')
      expect(EcMetal::Config.provider.options.vpc_subnet).to eq('subnet-5ac1133f')
      expect(EcMetal::Config.provider.options.ami).to eq('ami-09e27439')
      expect(EcMetal::Config.provider.options.ssh_username).to eq('ubuntu')
      expect(EcMetal::Config.provider.options.keypair_name).to be_nil
    end

    it "configurable keypair_name" do
      EcMetal::Config.provider.options.keypair_name = 'testkey'
      expect(EcMetal::Config.provider.options.keypair_name).to eq('testkey')
    end

    it "honors config_strict_mode" do
      expect { EcMetal::Config.provider.blah }.to raise_error(Mixlib::Config::UnknownConfigOptionError)
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

  context "server" do
    it "defaults with options" do
      expect(EcMetal::Config.server.version).to eq('latest')
      expect(EcMetal::Config.server.apply_ec_bugfixes).to be false
      expect(EcMetal::Config.server.run_pedant).to be true
      expect(EcMetal::Config.server.base_hostname).to eq('opscode.piab')
      expect(EcMetal::Config.server.package).to be_nil
    end

    it "configurable package" do
      EcMetal::Config.server.package = 'my_pkg'
      expect(EcMetal::Config.server.package).to eq('my_pkg')
    end

    context "settings" do
      it "api_fqdn default" do
        expect(EcMetal::Config.server.settings.api_fqdn).to eq('api.opscode.piab')
      end
    end
  end
end
