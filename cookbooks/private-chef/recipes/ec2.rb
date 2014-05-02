# encoding: utf-8

# Resize EBS root volume
execute 'Resize root EBS volume' do
  command 'resize2fs /dev/xvde && touch /.root_resized'
  action :run
  not_if { ::File.exists?('/.root_resized') }
end

case node['platform_family']
when 'rhel'
  %w(gcc libxml2-devel libxslt-devel).each do |develpkg|
    package develpkg
  end
end

gem_package 'fog' do
  gem_binary('/opt/chef/embedded/bin/gem')
  options('--no-rdoc --no-ri')
end

private_chef_backend_vip node['private-chef']['backend_vip']['ipaddress'] do
  only_if { node['private-chef']['backends'][node.name] &&
    node['private-chef']['backends'][node.name]['bootstrap'] == true }
  not_if "ls /var/opt/opscode/drbd/drbd_ready"
end

directory '/var/opt/opscode/keepalived/bin' do
  owner 'root'
  group 'root'
  mode '0700'
  recursive true
  action :create
end

template '/var/opt/opscode/keepalived/bin/ec2_assign_backend_vip.rb' do
  source 'ec2_assign_backend_vip.rb.erb'
  owner 'root'
  group 'root'
  mode '0700'
  only_if { node['private-chef']['backends'][node.name] }
end

installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)

# Delay the replacement of the EC packages cluster.sh.erb until the package is actually installed
cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/templates/default/cluster.sh.erb' do
  source 'cluster.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  only_if { node['private-chef']['backends'][node.name] }
  subscribes :create, "package[#{installer_name}]", :immediately
  action :nothing
end
