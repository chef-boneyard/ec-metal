require 'spec_helper'
require 'ec_metal/config'

describe EcMetal::Config do
  before(:each) do
    EcMetal::Config::Core.reset
  end

  context "provider type and options" do
    it "default to ec2 with ec2 options" do
      expect(EcMetal::Config::Core.provider.type).to eq('ec2')
      expect(EcMetal::Config::Core.provider.options.region).to eq('us-west-2')
      expect(EcMetal::Config::Core.provider.options.vpc_subnet).to eq('subnet-5ac1133f')
      expect(EcMetal::Config::Core.provider.options.ami).to eq('ami-09e27439')
      expect(EcMetal::Config::Core.provider.options.ssh_username).to eq('ubuntu')
      expect(EcMetal::Config::Core.provider.options.keypair_name).to be_nil
    end

    it "configurable keypair_name" do
      EcMetal::Config::Core.provider.options.keypair_name = 'testkey'
      expect(EcMetal::Config::Core.provider.options.keypair_name).to eq('testkey')
    end

    it "honors config_strict_mode" do
      expect { EcMetal::Config::Core.provider.blah }.to raise_error(Mixlib::Config::UnknownConfigOptionError)
    end
  end

  context "#build_hostname" do
    it "returns generated hostname with default base hostname" do
      expect(EcMetal::Config::Helper.build_hostname('built')).to eq('built.opscode.piab')
    end

    it "returns generated hostname with overridden base hostname" do
      EcMetal::Config::Core.server.base_hostname = 'getchef.com'
      expect(EcMetal::Config::Helper.build_hostname('built')).to eq('built.getchef.com')
    end
  end

  context "server" do
    it "defaults with options" do
      expect(EcMetal::Config::Core.server.version).to eq('latest')
      expect(EcMetal::Config::Core.server.apply_ec_bugfixes).to be false
      expect(EcMetal::Config::Core.server.run_pedant).to be true
      expect(EcMetal::Config::Core.server.base_hostname).to eq('opscode.piab')
      expect(EcMetal::Config::Core.server.package).to be_nil
    end

    it "configurable package" do
      EcMetal::Config::Core.server.package = 'my_pkg'
      expect(EcMetal::Config::Core.server.package).to eq('my_pkg')
    end

    context "settings" do
      it "api_fqdn default" do
        expect(EcMetal::Config::Core.server.settings.api_fqdn).to eq('api.opscode.piab')
      end
    end
  end
end
