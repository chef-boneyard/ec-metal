#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

# install

installer_file = node['private-chef']['installer_file']
installer_name = ::File.basename(installer_file)
installer_path = "#{Chef::Config[:file_cache_path]}/#{installer_name}"

if ::URI.parse(installer_file).absolute?
  remote_file installer_path do
    source installer_file
    checksum node['private-chef']['installer_checksum']
    action :create
  end
else
  installer_path = installer_file
end

node.set['private_chef']['perform_upgrade'] = false

if PackageHelper.private_chef_installed_version > PackageHelper.pc_version(installer_name)
  log "Installed package #{PackageHelper.private_chef_installed} is newer than installer #{installer_name}"
else
  package installer_name do
    source installer_path
    provider Chef::Provider::Package::Dpkg if platform_family?('debian')
    if PackageHelper.private_chef_installed_version < PackageHelper.pc_version(installer_name)
      action :upgrade
    else
      action :install
    end
  end

  if PackageHelper.private_chef_installed_version < PackageHelper.pc_version(installer_name)
    node.set['private_chef']['perform_upgrade'] = true
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
  variables(
    :backends => (node['private-chef']['backends'] || {}),
    :frontends => (node['private-chef']['frontends'] || {}),
    :backend_vip => (node['private-chef']['backend_vip'] || nil)
  )
  action :create
end


# # ensure the node can resolve the FQDNs locally
# [ node['private-chef']['api_fqdn'],
#   node['private-chef']['manage_fqdn'] ].each do |fqdn|

#   execute "echo 127.0.0.1 #{fqdn} >> /etc/hosts" do
#     not_if "host #{fqdn}" # host resolves
#     not_if "grep -q #{fqdn} /etc/hosts" # entry exists
#   end
# end

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
