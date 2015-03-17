# encoding: utf-8

# dumb stuff because the docker cookbook doesn't support Ubuntu 14.10 yet
if node['platform_family'] == 'debian' && node['platform_version'].to_f == 14.10
  default['docker']['package']['repo_url'] = 'https://get.docker.io/ubuntu'
  default['docker']['package']['name'] = 'lxc-docker'
  default['loadtester_host']['use_btrfs'] = true
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
