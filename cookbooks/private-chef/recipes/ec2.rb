# encoding: utf-8

topology = TopoHelper.new(ec_config: node['private-chef'])

rootdev = node.filesystem.select { |k,v| v['mount'] == '/' }.keys.first

# Resize EBS root volume
execute 'Resize root EBS volume' do
  command "resize2fs #{rootdev} && touch /.root_resized"
  action :run
  not_if { ::File.exists?('/.root_resized') }
end

# Unmount the cloud-init created /mnt on epheremal volumes automatically
execute 'Unmount /mnt' do
  command 'umount -f /mnt'
  action :run
  only_if 'grep /mnt /proc/mounts'
end

execute 'Remove /mnt from fstab' do
  command 'sed -i.bak "s/.*\/mnt.*//g" /etc/fstab'
  action :run
  only_if 'grep /mnt /etc/fstab'
end

case node['platform_family']
when 'rhel'
  %w(gcc libxml2-devel libxslt-devel).each do |develpkg|
    package develpkg
  end
when 'debian'
  include_recipe 'apt'
  %w(build-essential libxslt-dev libxml2-dev).each do |develpkg|
    package develpkg
  end
end

# temporary workaround until Nokogiri is fixed again - IP 11/11/2014
gem_package 'nokogiri' do
  gem_binary('/opt/chef/embedded/bin/gem')
  version '1.6.3.1'
  options('--no-rdoc --no-ri')
end

gem_package 'fog' do
  gem_binary('/opt/chef/embedded/bin/gem')
  options('--no-rdoc --no-ri')
end

directory '/var/opt/opscode/keepalived/bin' do
  owner 'root'
  group 'root'
  mode '0700'
  recursive true
  action :create
  only_if { topology.is_ha? }
  only_if { topology.is_backend?(node.name) }
end

template '/var/opt/opscode/keepalived/bin/ha_backend_ip' do
  source 'custom_backend_ip.vpc.erb'
  owner 'root'
  group 'root'
  mode '0700'
  only_if { topology.is_ha? }
  only_if { topology.is_backend?(node.name) }
end

installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)

if installer_name.include? 'private-chef'
  if PackageHelper.package_version(installer_name) > '11.0.0'
    cluster_source = 'cluster.sh.erb'
  elsif PackageHelper.package_version(installer_name) > '1.4.0'
    cluster_source = 'cluster.sh.pc14.erb'
  else
    raise 'EC2 operation not supported on Private chef < 1.4.0'
  end

  # Delay the replacement of the EC packages cluster.sh.erb until the package is actually installed
  cookbook_file '/opt/opscode/embedded/cookbooks/private-chef/templates/default/cluster.sh.erb' do
    source cluster_source
    owner 'root'
    group 'root'
    mode '0755'
    only_if { topology.is_backend?(node.name) }
    subscribes :create, "package[#{installer_name}]", :immediately
    action :nothing
  end
end
