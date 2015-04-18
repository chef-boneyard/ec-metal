
# chef-client cookbook overrides
default['chef_client']['splay']  = 1800
default['chef_client']['interval'] = 1800
# default['chef_client']['daemon_options'] = []
# default['chef_client']['cron']['use_cron_d'] = true
# default['chef_client']['cron']['log_file'] = '/var/log/chef-client.log'
# default['chef_client']['cron']['hour'] = '*'
# default['chef_client']['cron']['minute'] = '*/30'

# start cron in foreground mode because runit
default['container_service']['cron']['command'] = "/usr/sbin/cron -f -L15"
# default['container_service']['chef-client']['command'] = "chpst -P /usr/bin/chef-client -d -i #{node['chef_client']['interval']} -s #{node['chef_client']['splay']}"
default['container_service']['opscode-push-jobs-client']['command'] = "/opt/opscode-push-jobs-client/bin/pushy-client -c /etc/chef/push-jobs-client.rb"

# set environment
default['loadtester_guest']['chef_environment'] = 'loadtest'

# Push jobs settings
default['loadtester_guest']['push_jobs_enabled'] = false
default['push_jobs']['init_style'] = 'container'
default['push_jobs']['package_url'] = 'https://mark-testing.s3.amazonaws.com/opscode-push-jobs-client_1.1.5-1_amd64.deb?AWSAccessKeyId=AKIAIRISJZOEYLU52WCA&Expires=1457825224&Signature=zm2qixrhrI49RrqRwl1q5%2BsfS7w%3D'
default['push_jobs']['package_checksum'] = 'd7b40ebb18c7c7dbc32322c9bcd721279e707fd1bee3609a37055838afbf67ea'
default['push_jobs']['whitelist'] = {
  "chef-client" => "chef-client",
  "sleep" => "sleep 5"
}
