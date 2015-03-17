#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

# install

installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file.split('?').first)
installer_path = "#{Chef::Config[:file_cache_path]}/#{installer_name}"

topology = TopoHelper.new(ec_config: node['private-chef'])

if ::URI.parse(installer_file).absolute?
  remote_file installer_path do
    source installer_file
    retries 2
    action :create_if_missing
  end
else
  installer_path = installer_file
end

if Gem::Version.new(PackageHelper.private_chef_installed_version(node)) > Gem::Version.new(PackageHelper.package_version(installer_name))
  log "Installed package #{PackageHelper.private_chef_installed_version(node)} is newer than installer #{installer_name}"
else
  package installer_name do
    source installer_path
    provider Chef::Provider::Package::Rpm if platform_family?('rhel')
    provider Chef::Provider::Package::Dpkg if platform_family?('debian')
    action :install
  end

  if Gem::Version.new(PackageHelper.private_chef_installed_version(node)) < Gem::Version.new(PackageHelper.package_version(installer_name)) &&
    PackageHelper.private_chef_installed_version(node) != '0.0.0'
    file '/tmp/private-chef-perform-upgrade' do
      action :create
      owner 'root'
      group 'root'
      mode '0644'
      content "Running upgrade of #{installer_name} at #{Time.now}"
    end

    # Drop a special file for EC11->CS12 upgrades, now we must stop services on the backend master
    if PackageHelper.private_chef_installed_version(node).to_i == 11 &&
      PackageHelper.package_version(installer_name).to_i == 12 &&
      node.name == topology.bootstrap_node_name

      file '/tmp/upgrading_ec11_to_cs12' do
        action :create
        owner 'root'
        group 'root'
        mode '0644'
        content "Upgrading from #{PackageHelper.private_chef_installed_version(node)} to #{PackageHelper.package_version(installer_name)} at #{Time.now}"
      end

    end
  end
end

# configure
directory "/etc/opscode" do
  owner "root"
  group "root"
  recursive true
  action :create
end

template "/etc/opscode/private-chef.rb" do
  source "private-chef.rb.erb"
  owner "root"
  group "root"
  action :create
end

# SSH key management for inter-node trust
directory '/root/.ssh' do
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

file '/root/.ssh/id_rsa' do
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  content node['root_ssh']['privkey']
end

file '/root/.ssh/authorized_keys' do
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  content node['root_ssh']['pubkey']
end

file '/root/.ssh/config' do
  action :create
  owner 'root'
  group 'root'
  mode '0600'
  content "Host *\n  StrictHostKeyChecking no\n"
end
