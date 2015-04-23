#
# Cookbook Name:: loadtester_guest
# Recipe:: default
#
# Copyright (C) 2014
#

# Run chef-client from cron.  Saves memory vs daemonized chef-client
include_recipe 'chef-client::default'

# For running the push jobs client within your containers
if node['loadtester_guest']['push_jobs_enabled'] == true
  include_recipe 'push-jobs::default'
end
