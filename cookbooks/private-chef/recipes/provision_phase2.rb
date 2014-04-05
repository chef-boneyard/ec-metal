# encoding: utf-8
#
# Author:: Irving Popovetsky (<irving@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
#
# All Rights Reserved
#

bootstrap_node_name =
  node['private-chef']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.values.first['hostname']

package 'rsync'

# NOTE: order-of-operations!  This assumes that the machine resource for the bootstrap is running first
if node.name == bootstrap_node_name

  execute 'initial-p-c-c-reconfigure' do
    command '/opt/opscode/bin/private-chef-ctl reconfigure'
    action :run
  end

  unless node['private_chef']['perform_upgrade'] == true
    execute 'fix-migration-state' do
      command '/opt/opscode/embedded/bin/bundle exec bin/partybus init'
      cwd '/opt/opscode/embedded/service/partybus'
      action :run
      not_if { File.exists?('/var/opt/opscode/upgrades/migration-level') }
    end
  end

else

  execute 'rsync-from-bootstrap' do
    command "rsync -avz -e ssh --exclude chef-server-running.json root@#{bootstrap_node_name}:/etc/opscode/ /etc/opscode"
    action :run
  end

  execute 'p-c-c-reconfigure' do
    command '/opt/opscode/bin/private-chef-ctl reconfigure'
    action :run
  end

end

if node['private_chef']['perform_upgrade'] == true
  # If anything is still down, wait for things to settle
  execute 'waitforit' do
    command 'sleep 60'
    action :run
    only_if "/opt/opscode/bin/private-chef-ctl status | grep ^down"
  end

  # after 1.2->1.4 upgrade postgresql won't be running, but WHY?
  execute 'p-c-c-start' do
    command '/opt/opscode/bin/private-chef-ctl start'
    action :run
    only_if "/opt/opscode/bin/private-chef-ctl status | grep ^down"
  end

  execute 'p-c-c-upgrade' do
    command '/opt/opscode/bin/private-chef-ctl upgrade'
    action :run
  end

  execute 'p-c-c-cleanup' do
    command '/opt/opscode/bin/private-chef-ctl cleanup'
    action :run
  end
end
