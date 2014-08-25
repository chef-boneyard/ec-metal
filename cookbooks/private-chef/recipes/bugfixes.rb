installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)

topology = TopoHelper.new(ec_config: node['private-chef'])
pc_version = PackageHelper.package_version(installer_name)

# OC-11490 bug fix
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/keepalived.rb' do
  source 'keepalived.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11297
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/partybus.rb' do
  source 'partybus.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11657
cookbook_file '/opt/opscode/bin/private-chef-ctl' do
  source 'private-chef-ctl'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11575
cookbook_file '/opt/opscode/embedded/cookbooks/enterprise/definitions/component_runit_service.rb' do
  source 'component_runit_service.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# # OC-11382
# cookbook_file '/opt/opscode/embedded/service/omnibus-ctl/upgrade.rb' do
#   source 'upgrade.rb'
#   owner 'root'
#   group 'root'
#   mode '0644'
#   only_if { PackageHelper.private_chef_installed_version(node).match('^11.1') && topology.is_backend?(node.name) }
#   subscribes :create, "package[#{installer_name}]", :immediately
#   action :nothing
# end

# OC-11601
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/redis_lb.rb' do
  source 'redis_lb.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# OC-11669
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/default.rb' do
  source 'private_chef_default.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/resources/keepalived_safemode.rb' do
  source 'resources_keepalived_safemode.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/providers/keepalived_safemode.rb' do
  source 'providers_keepalived_safemode.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  action :nothing
end

# OC-11670
cookbook_file '/opt/opscode/embedded/upgrades/001/009_migrate_authz.rb' do
  source '009_migrate_authz.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { pc_version >= '11.0.0' && pc_version < '11.2.0' }
  only_if { topology.is_backend?(node.name) }
  action :nothing
end

# yet-unreported: enabling tweaking of oc_chef_authz attributes for erchef
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/libraries/private_chef.rb' do
  source 'libraries-private_chef.rb'
  owner 'root'
  group 'root'
  mode '0644'
  only_if { PackageHelper.private_chef_installed_version(node).match('^11.') }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# awesome support tools
cookbook_file '/usr/local/bin/opc-log-parser' do
  source 'opc-log-parser'
  owner 'root'
  group 'root'
  mode '0755'
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end
cookbook_file '/usr/local/bin/profile-request-rate' do
  source 'profile-request-rate'
  owner 'root'
  group 'root'
  mode '0755'
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# yet-unreported: bump up ['private_chef']['oc_chef_authz']['http_init_count']
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/attributes/default.rb' do
  source 'attributes-default.rb'
  owner 'root'
  group 'root'
  mode '0644'
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end

# awesome support tools
cookbook_file '/usr/local/bin/opc-log-parser' do
  source 'opc-log-parser'
  owner 'root'
  group 'root'
  mode '0755'
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end
cookbook_file '/usr/local/bin/profile-request-rate' do
  source 'profile-request-rate'
  owner 'root'
  group 'root'
  mode '0755'
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end
