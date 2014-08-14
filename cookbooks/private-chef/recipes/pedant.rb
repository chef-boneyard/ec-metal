execute 'run pedant' do
  if node['osc-install']
    command '/opt/chef-server/bin/chef-server-ctl test'
  else
    command '/opt/opscode/bin/private-chef-ctl test'
  end
  action :run
  only_if { node['run-pedant'] }
end

# OSC does not have orgs and does not understand default orgs
# Perhaps add a log message here
unless node['osc-install']
  execute 'run pedant in default-org mode' do
    command '/opt/opscode/bin/private-chef-ctl test --use-default-org --smoke'
    action :run
    only_if { node['run-pedant'] && node['private-chef']['default_orgname'] }
  end
end
