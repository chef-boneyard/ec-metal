#
# Cookbook Name:: private-chef
# Spec:: provision_phase2
#
# Copyright (c) 2015 Irving Popovetsky, All Rights Reserved.

require 'spec_helper'

describe 'private-chef::provision_phase2' do

  context 'When all attributes are default, on an unspecified platform' do

    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new do |node|
        node.automatic['name'] = 'standalone1'
        node.default['private-chef']['standalones'] = {
            "standalone1" => {
              "hostname" => "standalone1.chef.ecm",
              "bootstrap" => true
            }
        }
        node.default['analytics']['analytics_standalones'] = {
            "analytics-standalone1" => {
              "hostname" => "analytics-standalone1.chef.ecm",
              "bootstrap" => true
            }
        }
      end
      runner.converge(described_recipe)
    end

    before do
      stub_command("ls /tmp/private-chef-perform-upgrade").and_return('foo')
      stub_command("ls /var/opt/opscode/upgrades/migration-level").and_return('foo')
    end

    it 'converges successfully' do
      chef_run # This should not raise an error
    end

  end
end
