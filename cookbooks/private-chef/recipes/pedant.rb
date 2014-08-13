execute 'run pedant' do
  if node['osc-install']
    command '/opt/chef-server/bin/chef-server-ctl test'
  else
    command '/opt/opscode/bin/private-chef-ctl test'
  end
  action :run
  only_if { node['run-pedant'] }
end

execute 'run pedant in default-org mode' do
  if node['osc-install']
    fail '--default-org mode is not available for OSC'
  else
    command '/opt/opscode/bin/private-chef-ctl test --use-default-org'
  end
  action :run
  only_if { node['run-pedant'] && node['private-chef']['default_orgname'] }
end
