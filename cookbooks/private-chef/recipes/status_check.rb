# encoding: utf-8
#
# Author:: Irving Popovetsky (<irving@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
#
# All Rights Reserved
#

# TODO: Make chef-mover service removal dependent on upgrade state
file '/opt/opscode/service/opscode-chef-mover' do
  action :delete
end

# Status check, so we bomb if p-c-c status isn't clean
if node['harness']['vm_config']['backends'].include?(node.name)
  execute 'p-c-c-ha-status' do
    command '/opt/opscode/bin/private-chef-ctl ha-status'
    action :run
  end
else
  execute 'p-c-c-status' do
    command '/opt/opscode/bin/private-chef-ctl status'
    action :run
  end
end
