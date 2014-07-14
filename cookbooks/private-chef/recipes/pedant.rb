execute 'run pedant' do
  if node['osc-install']
    command '/opt/chef-server/bin/chef-server-ctl test'
  else
    command '/opt/opscode/bin/private-chef-ctl test'
  end
  action :run
  only_if { node['run-pedant'] }
end