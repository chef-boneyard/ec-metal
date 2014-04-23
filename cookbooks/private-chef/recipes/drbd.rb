
case node['platform_family']
when 'debian'
  include_recipe 'apt'
  package 'drbd8-utils'
when 'rhel'
  include_recipe 'yum'

  yum_key 'RPM-GPG-KEY-elrepo' do
    url 'http://elrepo.org/RPM-GPG-KEY-elrepo.org'
    action :add
  end

  remote_file '/tmp/elrepo.rpm' do
    case node['platform_version']
    when /^6/
      source 'http://elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm'
    when /^5/
      source 'http://elrepo.org/elrepo-release-5-5.el5.elrepo.noarch.rpm'
    end
  end

  rpm_package 'elrepo' do
    source '/tmp/elrepo.rpm'
  end

  %w(drbd84-utils kmod-drbd84).each do |i|
    package i
  end
end

# execute 'pvcreate /dev/sdb' do
#   action :run
#   not_if 'pvs |grep /dev/sdb'
# end

# execute 'vgcreate opscode /dev/sdb' do
#   action :run
#   not_if 'vgs | grep opscode'
# end

# # The size of our LV will be dependent upon the VG size,
# # which is depdent upon the VM's disk2 size
# execute 'lvcreate -l 80%VG -n drbd opscode' do
#   action :run
#   not_if 'lvs |grep drbd'
# end


# Charge ahead with a mocked-up drbd config to get us started

# borrowed from opscode-omnibus
drbd_dir = '/var/opt/opscode/drbd'
drbd_etc_dir =  File.join(drbd_dir, 'etc')
drbd_data_dir = File.join(drbd_dir, 'data')

[ drbd_dir, drbd_etc_dir, drbd_data_dir ].each do |dir|
  directory dir do
    recursive true
    mode '0755'
  end
end

# LVM setup for DRBD volume
include_recipe 'lvm::default'

lvm_volume_group 'opscode' do
  physical_volumes node['private-chef']['drbd_disks']

  logical_volume 'drbd' do
    size        '80%VG'
    # filesystem  'ext4'
    # mount_point :location => drbd_data_dir, :options => 'noauto,noatime'
    stripes     node['private-chef']['drbd_disks'].length
  end
end

template File.join(drbd_etc_dir, 'drbd.conf') do
  source 'drbd.conf.erb'
  mode '0655'
  not_if { File.exists?(File.join(drbd_etc_dir, 'drbd.conf')) }
end

template File.join(drbd_etc_dir, 'pc0.res') do
  source 'pc0.res.erb'
  mode '0655'
  variables(
    :backends => (node['private-chef']['backends'] || {}),
    )
  not_if { File.exists?(File.join(drbd_etc_dir, 'pc0.res')) }
end

execute 'mv /etc/drbd.conf /etc/drbd.conf.orig' do
  only_if { File.exists?('/etc/drbd.conf') && !File.symlink?('/etc/drbd.conf') }
end

link '/etc/drbd.conf' do
  to File.join(drbd_etc_dir, 'drbd.conf')
end

template File.join(drbd_etc_dir, 'drbd.conf') do
  source 'drbd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  not_if { ::File.exists?(File.join(drbd_etc_dir, 'drbd.conf')) }
end

# Debian/Ubuntu defaults to *not* starting the service by default
if node['platform_family'] == 'debian'
  execute 'start-drbd-service-with-timeout' do
    command 'timeout 20 service drbd start; exit 0'
    action :run
    not_if "lsmod | grep drbd"
  end
end

execute 'create-md' do
  command 'drbdadm create-md pc0'
  action :run
  only_if 'drbdadm dump-md pc0 2>&1 | grep "No valid meta data"'
  notifies :run, 'execute[drbdadm-up]', :immediately
end

execute 'drbdadm-up' do
  command 'drbdadm up pc0'
  action :nothing
  notifies :run, 'execute[drbd-primary-force]', :immediately
end

# TODO: more reliably detect if we are an unconfigured bootstrap node
execute 'drbd-primary-force' do
  if node['platform_family'] == 'debian'
    command 'drbdadm -- --overwrite-data-of-peer primary pc0'
  else
    command 'drbdadm primary --force pc0'
  end
  action :run
  notifies :run, 'execute[mkfs-drbd-volume]', :immediately
  only_if { node['private-chef']['backends'][node.name]['bootstrap'] == true }
  not_if { File.exists?(File.join(drbd_dir, 'drbd_ready')) }
end

execute 'mkfs-drbd-volume' do
  command 'mkfs.ext4 /dev/drbd0'
  action :nothing
  notifies :run, 'execute[mount-drbd-volume]', :immediately
  not_if 'file -sL /dev/drbd0 | grep ext4'
end

execute 'mount-drbd-volume' do
  command 'mount /dev/drbd0 /var/opt/opscode/drbd/data'
  action :nothing
  not_if 'mount | grep /dev/drbd0'
end

# touch the drbd_ready file - possibly dangerous to do this early
file File.join(drbd_dir, 'drbd_ready') do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  content "Created by ec-harness"
end
