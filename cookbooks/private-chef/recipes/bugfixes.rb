installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)

# OC-11490 bug fix
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/keepalived.rb' do
  source 'keepalived.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11297
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/partybus.rb' do
  source 'partybus.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11657
cookbook_file '/opt/opscode/bin/private-chef-ctl' do
  source 'private-chef-ctl'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11575
cookbook_file '/opt/opscode/embedded/cookbooks/enterprise/definitions/component_runit_service.rb' do
  source 'component_runit_service.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11382
cookbook_file '/opt/opscode/embedded/service/omnibus-ctl/upgrade.rb' do
  source 'upgrade.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11669
cookbook_file '/opt/opscode/embedded/cookbooks/enterprise/recipes/runit_upstart.rb' do
  source 'runit_upstart.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/resources/keepalived_safemode.rb' do
  source 'resources_keepalived_safemode.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/providers/keepalived_safemode.rb' do
  source 'providers_keepalived_safemode.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11670
cookbook_file '/opt/opscode/embedded/upgrades/001/009_migrate_authz.rb' do
  source '009_migrate_authz.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end
