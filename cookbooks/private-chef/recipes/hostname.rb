# encoding: utf-8

myhostname = TopoHelper.new(ec_config: node['private-chef']).myhostname(node.name)

# Opscode-omnibus wants hostname == fqdn, so we have to do this grossness
execute 'force-hostname-fqdn' do
  command "hostname #{myhostname}"
  action :run
  not_if { myhostname == `/bin/hostname` }
end

file '/etc/hostname' do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  content "#{myhostname}\n"
end

# Needed for hostname to survive reboots
if node['platform_family'] == 'rhel'
  file '/etc/sysconfig/network' do
    action :create
    owner "root"
    group "root"
    mode "0644"
    content "NETWORKING=yes\nHOSTNAME=#{myhostname}\n"
  end
end
