
# chef-client cookbook overrides
default['chef_client']['splay']  = '300'
default['chef_client']['daemon_options'] = []
default['chef_client']['cron']['use_cron_d'] = true
default['chef_client']['cron']['log_file'] = '/var/log/chef-client.log'
default['chef_client']['cron']['hour'] = '*'
default['chef_client']['cron']['minute'] = '*/30'
default["chef_client"]["splay"] = 1800

# start cron in foreground mode because runit
default['container_service']['cron']['command'] = "/usr/sbin/cron -f -L15"
default['container_service']['opscode-push-jobs-client']['command'] = "/opt/opscode-push-jobs-client/bin/pushy-client -c /etc/chef/push-jobs-client.rb"

# set environment
default['loadtester_guest']['chef_environment'] = 'loadtest'
