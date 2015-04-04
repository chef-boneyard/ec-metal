#
# Cookbook Name:: ec-harness
# Spec:: default
#
# Copyright (c) 2015 Irving Popovetsky, All Rights Reserved.


harness_dir = ::File.join(::File.dirname(__FILE__), '..', '..', '..', '..', '..')
ENV['HARNESS_DIR'] = harness_dir
ENV['ECM_CONFIG'] = ::File.join(harness_dir, 'examples', 'config.json.example')
ENV['ECM_CHEF_REPO'] = ::File.join(harness_dir, 'chef-repo')

require 'spec_helper'

describe 'ec-harness::default' do

  context 'When all attributes are default, on an unspecified platform' do

    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      chef_run # This should not raise an error
    end

  end
end
