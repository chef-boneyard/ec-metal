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

#
#
#
node.set['push_jobs']['init_style'] = 'plain'

node.set['push_jobs']['package_url'] = 'https://mark-testing.s3.amazonaws.com/opscode-push-jobs-client_1.1.5-1_amd64.deb?AWSAccessKeyId=AKIAIRISJZOEYLU52WCA&Expires=1457825224&Signature=zm2qixrhrI49RrqRwl1q5%2BsfS7w%3D'
node.set['push_jobs']['package_checksum'] = 'd7b40ebb18c7c7dbc32322c9bcd721279e707fd1bee3609a37055838afbf67ea'

node.set['push_jobs']['whitelist'] = {
  "chef-client" => "chef-client",
  "sleep" => "sleep 5"
}

include_recipe 'push-jobs::default'

