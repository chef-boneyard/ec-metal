# encoding: utf-8

# docker 1.4.x giving me DM issues
default['docker']['version'] = '1.3.3'

# from: http://developerblog.redhat.com/2014/09/30/overview-storage-scalability-docker/
# note: this also still needs work before ready for primetime
default['loadtester_host']['use_direct_lvm'] = false

if node['loadtester_host']['use_direct_lvm'] == true
  default['docker']['options'] = %w(
    --storage-opt dm.datadev=/dev/docker/data
    --storage-opt dm.metadatadev=/dev/docker/metadata
    --storage-opt dm.fs=xfs).join(' ')
end

# btrfs is still too buggy to use, but someday :)
default['loadtester_host']['use_btrfs'] = false

if node['loadtester_host']['use_btrfs'] == true
  default['docker']['options'] = '-s btrfs'
end
