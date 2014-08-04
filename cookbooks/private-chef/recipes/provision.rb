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

chef_package = EcMetal::ChefPackageInfo.new(installer_name)
node_package = EcMetal::NodePackageHelper.new(node)

if ::URI.parse(installer_file).absolute?
  remote_file installer_path do
    source installer_file
    retries 2
    action :create_if_missing
  end
else
  installer_path = installer_file
end

if node_package.chef_installed?
  if node_package.ec_installed?
    if chef_package.server_type == :ec
      # if package is newer than installed version
        # install
        # tag as an ec upgrade
      # else
        # fail
      # end
    end
    if chef_package.server_type == :osc
      # if package is :ec and version >= "12" || "11.1.99"
        # install
        # tag as an ec upgrade
      # else
        # fail
      # end
    end
  end
else
  # install
end

package installer_name do
  action :nothing
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform_family?('debian')
  options '--nogpgcheck' if platform_family?('rhel') && node['platform_version'].to_i == 5
end

file '/tmp/private-chef-perform-upgrade' do
  action :nothing
  owner 'root'
  group 'root'
  mode '0644'
  content "Running upgrade of #{installer_name} at #{Time.now}"
end






if Gem::Version.new(PackageHelper.private_chef_installed_version(node)) > Gem::Version.new(chef_package.version)
  log "Installed package #{PackageHelper.private_chef_installed_version(node)} is newer than installer #{installer_name}"
else
  package installer_name do
    source installer_path
    provider Chef::Provider::Package::Dpkg if platform_family?('debian')
    options '--nogpgcheck' if platform_family?('rhel') &&
      node['platform_version'].to_i == 5
    action :install
  end

  if Gem::Version.new(PackageHelper.private_chef_installed_version(node)) < Gem::Version.new(chef_package.version) &&
    PackageHelper.private_chef_installed_version(node) != '0.0.0'
    file '/tmp/private-chef-perform-upgrade' do
      action :create
      owner 'root'
      group 'root'
      mode '0644'
      content "Running upgrade of #{installer_name} at #{Time.now}"
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

# RHEL-specific bug fixes
if node['platform_family'] == 'rhel'
  # Deal with RHEL-based boxes that may have their own firewalls up
  service 'iptables' do
    action [ :disable, :stop ]
  end

  # As of EC11.1.8, we need to disable sudo 'requiretty' on RHEL-based systems
  execute 'sudoers-disable-requiretty' do
    command 'sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers'
    action :run
    only_if 'grep "^Defaults.*requiretty" /etc/sudoers'
  end
end
