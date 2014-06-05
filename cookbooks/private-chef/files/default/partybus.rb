#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved

upgrades_dir = node['private_chef']['upgrades']['dir']
upgrades_etc_dir = File.join(upgrades_dir, "etc")
upgrades_service_dir = "/opt/opscode/embedded/service/partybus"
[
  upgrades_dir,
  upgrades_etc_dir,
  upgrades_service_dir
].each do |dir_name|
  directory dir_name do
    owner node['private_chef']['user']['username']
    mode '0700'
    recursive true
  end
end

partybus_config = File.join(upgrades_etc_dir, "config.rb")
db_service_name = "postgres"

# set the node role
node_role = node['private_chef']['role']

template partybus_config do
  source "partybus_config.rb.erb"
  owner node['private_chef']['user']['username']
  mode   "0644"
  variables(:connection_string => OmnibusHelper.new(node).db_connection_uri,
            :node_role => node_role,
            :db_service_name => db_service_name,
            :is_data_master => is_data_master?,
            :bootstrap_server => is_bootstrap_server?)
end

link "/opt/opscode/embedded/service/partybus/config.rb" do
  to partybus_config
end

execute "set initial migration level" do
  action :nothing
  command "cd /opt/opscode/embedded/service/partybus && ./bin/partybus init"
  subscribes :run, resources(:directory => "/var/opt/opscode"), :delayed
  subscribes :run, resources(:directory => "/var/opt/opscode/postgresql"), :delayed
end

ruby_block 'migration-level file sanity check' do
  block do
    begin
      ::JSON.parse(::File.read('/var/opt/opscode/upgrades/migration-level'))
    rescue Exception => e
      message = <<-EOF
ERROR:
The /var/opt/opscode/upgrades/migration-level file is missing or corrupt!  Please read http://docs.opscode.com/upgrade_server_ha_notes.html#pre-flight-check and correct this file before proceeding

* If this is a new installation:
  run: "cd /opt/opscode/embedded/service/partybus ; /opt/opscode/embedded/bin/bundle exec bin/partybus init"
* If you have upgraded a previous installation:
  copy the /var/opt/opscode/upgrades/migration-level file from a not-yet-upgraded FrontEnd node

Error message #{e}
EOF

      raise message
    end
  end
  not_if 'ls /var/opt/opscode/upgrades/migration-level'
  action :nothing
  subscribes :run, 'private-chef_pg_upgrade[upgrade_if_necessary]', :delayed
end
