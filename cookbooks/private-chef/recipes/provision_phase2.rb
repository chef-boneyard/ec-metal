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

  execute 'fix-migration-state' do
    command '/opt/opscode/embedded/bin/bundle exec bin/partybus init'
    cwd '/opt/opscode/embedded/service/partybus'
    action :run
    not_if { File.exists?('/var/opt/opscode/upgrades/migration-level') }
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
