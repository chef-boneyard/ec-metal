#
# Cookbook Name:: docker_host
# Recipe:: default
#
# Copyright (C) 2014
#
#
#

# Assumes Ubuntu 14.04, others to follow

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

package 'btrfs-tools'

# Format the two ephemeral disks #ASSUMPTIONS
execute 'btrfs-format' do
  command 'mkfs.btrfs -f /dev/xvdb'
  action :run
  not_if "file -sL /dev/xvdb | grep BTRFS"
end

directory '/var/lib/docker' do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

execute 'btrfs-mount-docker' do
  command 'mount /dev/xvdb /var/lib/docker'
  not_if 'mount | grep /var/lib/docker'
end

execute 'mkswap' do
  command 'mkswap /dev/xvdc'
  action :run
  not_if "file -sL /dev/xvdc | grep swap"
end

execute 'swapon' do
  command "swapon /dev/xvdc"
  action :run
  not_if 'grep /dev/xvdc /proc/swaps'
end

include_recipe 'docker'

chef_gem 'knife-container'

directory '/etc/chef/secure/certs' do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end


execute 'container init' do
  command "knife container docker init ponyville/ubuntu --include-credentials " +
  "--force --trusted-certs /etc/chef/secure/certs/ " +
  "--server-url #{Chef::Config[:chef_server_url]} " +
  "--validation-key /etc/chef/validation.pem " +
  "--validation-client-name ponyville-validator" +
  "-r 'recipe[openssh]' -b"
  action :run
  not_if 'docker images |grep ponyville/ubuntu'
end

execute 'fucking ssl stfu' do
  command 'sed -i s/ssl_verify_mode.*/verify_api_cert\ false/ /var/chef/dockerfiles/ponyville/ubuntu/chef/client.rb'
  action :run
  not_if 'grep verify_api_cert /var/chef/dockerfiles/ponyville/ubuntu/chef/client.rb'
end

file '/var/chef/dockerfiles/ponyville/ubuntu/chef/.node_name' do
  action :create
  owner "root"
  group "root"
  mode "0644"
  content "build-#{node.name}\n"
end

execute 'container build' do
  command "knife container docker build ponyville/ubuntu --no-berks || exit 0"
  action :run
  not_if 'docker images |grep ponyville/ubuntu'
end
