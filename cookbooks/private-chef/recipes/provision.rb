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

package installer_name do
  source installer_path
  provider Chef::Provider::Package::Dpkg if platform?("ubuntu","debian")
  action :install
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
  notifies :run, "execute[reconfigure-private-chef]", :immediately
end

execute "reconfigure-private-chef" do
  command "private-chef-ctl reconfigure"
  action :nothing
  not_if { node['private-chef']['topology'] =~ /ha/ }
end

# ensure the node can resolve the FQDNs locally
[ node['private-chef']['api_fqdn'],
  node['private-chef']['manage_fqdn'] ].each do |fqdn|

  execute "echo 127.0.0.1 #{fqdn} >> /etc/hosts" do
    not_if "host #{fqdn}" # host resolves
    not_if "grep -q #{fqdn} /etc/hosts" # entry exists
  end
end
