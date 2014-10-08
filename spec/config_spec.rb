require 'spec_helper'
require 'ec_metal/config'

describe EcMetal::Config do
  before(:each) do
    EcMetal::Config.reset
  end

  context "provider" do
    it "defaults and default options" do
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

  context "server" do
    it "defaults and default options" do
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

    context "#build_hostname" do
      it "returns generated hostname with default base hostname" do
        expect(EcMetal::Config.build_hostname('built')).to eq('built.opscode.piab')
      end

      it "returns generated hostname with overridden base hostname" do
        EcMetal::Config.server.base_hostname = 'getchef.com'
        expect(EcMetal::Config.build_hostname('built')).to eq('built.getchef.com')
      end
    end

    context "topology" do
      it "default type and config" do
        expect(EcMetal::Config.server.topology.type).to eq('standalone')
      end
    end
  end

  context "manage" do
    it "defaults" do
      expect(EcMetal::Config.addon.manage.version).to eq('release')
      expect(EcMetal::Config.addon.manage.fqdn).to eq('manage.opscode.piab')
      expect(EcMetal::Config.addon.manage.settings).to be_nil
      expect(EcMetal::Config.addon.manage.package).to be_nil
    end
  end

  context "push_jobs" do
    it "defaults" do
      expect(EcMetal::Config.addon.push_jobs.version).to eq('release')
      expect(EcMetal::Config.addon.push_jobs.settings).to be_nil
      expect(EcMetal::Config.addon.push_jobs.package).to be_nil
    end
  end

  context "reporting" do
    it "defaults" do
      expect(EcMetal::Config.addon.reporting.version).to eq('release')
      expect(EcMetal::Config.addon.reporting.settings).to be_nil
      expect(EcMetal::Config.addon.reporting.package).to be_nil
    end
  end

  context "analytics" do
    it "defaults" do
      expect(EcMetal::Config.analytics.version).to eq('release')
      expect(EcMetal::Config.analytics.package).to be_nil
      expect(EcMetal::Config.analytics.fqdn).to eq('analytics.opscode.piab')
      expect(EcMetal::Config.analytics.settings).to be_nil
    end
    context "topology" do
      it "defaults" do
        expect(EcMetal::Config.analytics.topology.type).to eq('standalone')
      end
    end
  end
end
