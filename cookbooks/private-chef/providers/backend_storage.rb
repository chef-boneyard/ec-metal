
action :drbd do
  install_drbd_packages
  create_drbd_dirs
  create_lvm
  create_drbd_config_files
  setup_drbd
  touch_drbd_ready
  new_resource.updated_by_last_action(true)
end

def install_drbd_packages
  case node['platform_family']
  when 'debian'
    package 'drbd8-utils'
  when 'rhel'
    yum_key 'RPM-GPG-KEY-elrepo' do
      url 'http://elrepo.org/RPM-GPG-KEY-elrepo.org'
      action :add
    end

    maj = node['platform_version'].to_i
    remote_file '/tmp/elrepo.rpm' do
      source "http://elrepo.org/elrepo-release-#{maj}-#{maj}.el#{maj}.elrepo.noarch.rpm"
      action :create_if_missing
    end

    rpm_package 'elrepo' do
      source '/tmp/elrepo.rpm'
    end

    %w(drbd84-utils kmod-drbd84).each do |i|
      package i
    end
  end
end


DRBD_DIR = '/var/opt/opscode/drbd'
DRBD_ETC_DIR =  ::File.join(DRBD_DIR, 'etc')
DRBD_DATA_DIR = ::File.join(DRBD_DIR, 'data')

def create_drbd_dirs
  [ DRBD_DIR, DRBD_ETC_DIR, DRBD_DATA_DIR ].each do |dir|
    directory dir do
      recursive true
      mode '0755'
    end
  end
end

def create_lvm
  lvm_volume_group 'opscode' do
    physical_volumes node['private-chef']['drbd_disks']

    logical_volume 'drbd' do
      size        '80%VG'
      stripes     node['private-chef']['drbd_disks'].length
    end
  end
end

def create_drbd_config_files
  template ::File.join(DRBD_ETC_DIR, 'drbd.conf') do
    source 'drbd.conf.erb'
    mode '0655'
    not_if { ::File.exists?(::File.join(DRBD_ETC_DIR, 'drbd.conf')) }
  end

  template ::File.join(DRBD_ETC_DIR, 'pc0.res') do
    source 'pc0.res.erb'
    mode '0655'
    not_if { ::File.exists?(::File.join(DRBD_ETC_DIR, 'pc0.res')) }
  end

  execute 'mv /etc/drbd.conf /etc/drbd.conf.orig' do
    only_if { ::File.exists?('/etc/drbd.conf') && !::File.symlink?('/etc/drbd.conf') }
  end

  link '/etc/drbd.conf' do
    to ::File.join(DRBD_ETC_DIR, 'drbd.conf')
  end
end

def setup_drbd
  # Debian/Ubuntu defaults to *not* starting the service by default
  if node['platform_family'] == 'debian'
    execute 'start-drbd-service-with-timeout' do
      command 'timeout 20 service drbd start; exit 0'
      action :run
      not_if "lsmod | grep drbd"
    end
  end

  execute 'create-md' do
    command 'yes yes | drbdadm create-md pc0'
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
    not_if { ::File.exists?(::File.join(DRBD_DIR, 'drbd_ready')) }
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
end

def touch_drbd_ready
  file ::File.join(DRBD_DIR, 'drbd_ready') do
    action :create
    owner 'root'
    group 'root'
    mode '0644'
    content "Created by ec-harness"
  end
end
