# encoding: utf-8

# dumb stuff because the docker cookbook doesn't support Ubuntu 14.10 yet
if node['platform_family'] == 'debian' && node['platform_version'].to_f == 14.10
  default['loadtester_host']['use_btrfs'] = true
elsif node['platform_family'] == 'debian' && node['platform_version'].to_f == 15.04
  default['loadtester_host']['use_overlayfs'] = true
  default['docker']['ipv4_forward'] = false
  default['docker']['ipv6_forward'] = false
else
  # docker 1.4.x giving me devicemapper issues
  default['docker']['version'] = '1.3.3'
  # btrfs is still too buggy to use, but someday :)
  default['loadtester_host']['use_btrfs'] = false
end

# from: http://developerblog.redhat.com/2014/09/30/overview-storage-scalability-docker/
# note: this also still needs work before ready for primetime
default['loadtester_host']['use_direct_lvm'] = false

if node['loadtester_host']['use_direct_lvm'] == true
  default['docker']['options'] = %w(
    --storage-opt dm.datadev=/dev/docker/data
    --storage-opt dm.metadatadev=/dev/docker/metadata
    --storage-opt dm.fs=xfs).join(' ')
end

if node['loadtester_host']['use_btrfs'] == true
  default['docker']['options'] = '-s btrfs'
end

if node['loadtester_host']['use_overlayfs'] == true
  default['docker']['options'] = '-s overlay'
end
