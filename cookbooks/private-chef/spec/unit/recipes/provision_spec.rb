#
# Cookbook Name:: private-chef
# Spec:: provision
#
# Copyright (c) 2015 Irving Popovetsky, All Rights Reserved.

require 'spec_helper'

describe 'private-chef::provision' do

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

    it 'converges successfully' do
      chef_run # This should not raise an error
    end

  end
end
