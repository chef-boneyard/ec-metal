#
# Cookbook Name:: docker_host
# Recipe:: default
#
# Copyright (C) 2014
#
#
#

# Assumes Ubuntu 14.04, others to follow

directory '/etc/chef/ohai/hints' do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

file '/etc/chef/ohai/hints/ec2.json' do
  action :create
  owner "root"
  group "root"
  mode "0644"
end

ohai_hint 'ec2'
include_recipe 'ohai'

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
  command 'mkfs.btrfs -f -d raid0 /dev/xvdb /dev/xvdc'
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

include_recipe 'docker'

chef_gem 'knife-container'

gem_package 'berkshelf' do
  gem_binary '/opt/chef/embedded/bin/gem'
end

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
  "--validation-client-name ponyville-validator " +
  "-r 'recipe[chef-client]'"
  action :run
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
  content "#{node.name}\n"
end

execute 'container build' do
  command "knife container docker build ponyville/ubuntu || exit 0"
  action :run
end

# bash 'docker attack' do
#   user "root"
#   cwd "/root"
#   code <<-EOH
#   for i in {1..2000}; do docker run -d ponyville/ubuntu; done
#   EOH
#   not_if 'test -f /dockers_launched'
# end

# file "/dockers_launched" do
#   action :create_if_missing
#   owner "root"
#   group "root"
#   mode "0644"
#   content "#{Time.now}"
# end



