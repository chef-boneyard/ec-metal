#
# Cookbook Name:: loadtester_guest
# Recipe:: default
#
# Copyright (C) 2014
#

# TODO: figure out sane way to create environments and bootstrap containers into one
# node.chef_environment = ['loadtester_guest']['chef_environment']

# Run chef-client from cron.  Saves memory vs daemonized chef-client
include_recipe 'chef-client::cron'

service 'cron' do
  action :start
end
