# encoding: utf-8


execute 'p-c-c-stop' do
  command '/opt/opscode/bin/private-chef-ctl stop'
  action :run
end
