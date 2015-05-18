# encoding: utf-8

topology = TopoHelper.new(ec_config: node['private-chef'])

rootdev = node.filesystem.select { |k,v| v['mount'] == '/' }.keys.first
rootdisk, rootpartition = rootdev.partition(/[0-9]/)

ephemeraldev = node.filesystem.select { |k,v| v['mount'] == '/mnt' }.keys.first || '/dev/null'

def is_gpt?(rootdisk)
  parted = `parted #{rootdisk} print -ms | grep ^#{rootdisk}`.split(':')[5]
  parted == 'gpt'
end

# Resize EBS root volume
# special case for RHEL/HVM AMIs that require a reboot to notice the resized disk
if node['platform_family'] == 'rhel' && node['platform_version'].to_f < 7.1
  if is_gpt?(rootdisk)
    reboot 'diskresize' do
      action :cancel
      delay_mins 1
    end

    package 'gdisk'

    execute 'Resize root EBS volume' do
      command "growpart --update off #{rootdisk} #{rootpartition} && touch /.root_resized"
      action :run
      not_if { ::File.exists?('/.root_resized') }
      notifies :request_reboot, 'reboot[diskresize]'
    end
  else
    execute 'Resize root EBS volume' do
      command "resize2fs #{rootdev} && touch /.root_resized"
      action :run
      not_if { ::File.exists?('/.root_resized') }
    end
  end
end

# Unmount the cloud-init created /mnt on epheremal volumes automatically
execute 'Unmount /mnt' do
  command 'umount -f /mnt'
  action :run
  only_if 'grep /mnt /proc/mounts'
  notifies :run, 'execute[wipe-ephemeral-disk]'
end

# stupid wipe trick because of https://github.com/opscode-cookbooks/lvm/issues/45
execute 'wipe-ephemeral-disk' do
  command "dd if=/dev/zero of=#{ephemeraldev} bs=1M count=10"
  action :nothing
  only_if "file -sL #{ephemeraldev} | grep ext3"
  only_if { node['platform_family'] == 'rhel' && node['platform_version'].to_i == 7 }
end

execute 'Remove /mnt from fstab' do
  command 'sed -i.bak "s/.*\/mnt.*//g" /etc/fstab'
  action :run
  only_if 'grep /mnt /etc/fstab'
end

# not needed now with ChefDK
# case node['platform_family']
# when 'rhel'
#   %w(gcc libxml2-devel libxslt-devel).each do |develpkg|
#     package develpkg
#   end
# when 'debian'
#   include_recipe 'apt'
#   %w(build-essential libxslt-dev libxml2-dev).each do |develpkg|
#     package develpkg
#   end
# end

# # temporary workaround until Nokogiri is fixed again - IP 11/11/2014
# gem_package 'nokogiri' do
#   gem_binary('/opt/chef/embedded/bin/gem')
#   version '1.6.3.1'
#   if node['platform_family'] == 'rhel'
#     options('--no-rdoc --no-ri -- --use-system-libraries')
#   else
#     options('--no-rdoc --no-ri')
#   end
# end

# gem_package 'fog' do
#   gem_binary('/opt/chef/embedded/bin/gem')
#   options('--no-rdoc --no-ri')
# end

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
