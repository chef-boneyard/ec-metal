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