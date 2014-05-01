installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)

cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/recipes/keepalived.rb' do
  source 'keepalived.rb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { PackageHelper.private_chef_installed_version.match('^11.') && node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end
