# encoding: utf-8

case node['platform_family']
when 'rhel'
  %w(gcc libxml2-devel libxslt-devel).each do |develpkg|
    package develpkg
  end
end

gem_package 'fog' do
  gem_binary('/opt/chef/embedded/bin/gem')
  options('--no-rdoc --no-ri')
end

private_chef_backend_vip node['private-chef']['backend_vip']['ipaddress'] do
  only_if { node['private-chef']['backends'][node.name] &&
    node['private-chef']['backends'][node.name]['bootstrap'] == true }
  not_if "ls /var/opt/opscode/drbd/drbd_ready"
end