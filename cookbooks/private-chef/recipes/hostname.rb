# encoding: utf-8

# Get my hostname from the frontend or backend "hostname" attribute
def getmyhostname
  mydata = node['private-chef']['backends'].
    merge(node['private-chef']['frontends']).
    select { |k,v| k == node.name }.values.first
  mydata['hostname']
end

myhostname = getmyhostname

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