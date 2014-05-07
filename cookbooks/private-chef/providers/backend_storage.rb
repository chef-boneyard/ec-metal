
action :drbd do
  install_drbd_packages
  create_drbd_dirs
  create_lvm
  create_drbd_config_files
  setup_drbd
  touch_drbd_ready
  new_resource.updated_by_last_action(true)
end

action :ebs_shared do
  install_drbd_packages # Needed because of raise in opscode-omnibus drbd.rb
  create_drbd_dirs
  if node['private-chef']['backends'][node.name]['bootstrap'] == true
    attach_ebs_volume
    create_lvm
    mount_ebs
    save_ebs_volumes_db
  else
    set_ebs_volume_on_standby
  end
  touch_drbd_device # stupid hack to trick ha-status into being OK
  touch_drbd_ready
  new_resource.updated_by_last_action(true)
end

action :ebs_save_databag do
  save_ebs_volumes_db
end

def bootstrap_host_name
  node['private-chef']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.values.first['hostname']
end

def create_ebs_volumes_db
  ebs_volumes_db_new = Chef::DataBag.new
  ebs_volumes_db_new.name('ebs_volumes_db')
  ebs_volumes_db_new.save
end

def save_ebs_volumes_db
  ruby_block 'save EBS volume_id to databag' do
    block do
      bootstrap_host_name =
        node['private-chef']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.values.first['hostname']
      Chef::Log.info "Saving EBS volume id = #{node['aws']['ebs_volume'][bootstrap_host_name]['volume_id']}"
      databag_item = Chef::DataBagItem.new
      databag_item.data_bag('ebs_volumes_db')
      databag_item.raw_data = {
        'id' => bootstrap_host_name,
        'volume_id' => node['aws']['ebs_volume'][bootstrap_host_name]['volume_id']
      }
      databag_item.save
    end
  end
end

def get_ebs_volumes_db
  item = data_bag_item('ebs_volumes_db', bootstrap_host_name)
  item['volume_id']
end

def create_ebs_volume
  aws_ebs_volume bootstrap_host_name do
    aws_access_key node['cloud']['aws_access_key_id']
    aws_secret_access_key node['cloud']['aws_secret_access_key']
    size node['cloud']['ebs_disk_size'].to_i
    device '/dev/sdc'
    if node['cloud']['ebs_use_piops'] == true
      volume_type 'io1'
      piops_val = node['cloud']['ebs_disk_size'].to_i * 30
      piops_val = 4000 if piops_val > 4000
      piops piops_val
    end
    action [ :create, :attach ]
  end
end

def attach_ebs_volume
  begin
    ebs_volumes_db = data_bag('ebs_volumes_db')
  rescue Exception
    create_ebs_volumes_db
    ebs_volumes_db = data_bag('ebs_volumes_db')
  end

  unless ebs_volumes_db.include?(bootstrap_host_name)
    create_ebs_volume
  else
    aws_ebs_volume bootstrap_host_name do
      aws_access_key node['cloud']['aws_access_key_id']
      aws_secret_access_key node['cloud']['aws_secret_access_key']
      volume_id get_ebs_volumes_db
      device '/dev/sdc'
      action :attach
    end
  end

  node.override['private-chef']['drbd_disks'] = ['/dev/xvdg']
end

def set_ebs_volume_on_standby
  node.override['aws']['ebs_volume'][bootstrap_host_name]['volume_id'] = get_ebs_volumes_db
end

def install_drbd_packages
  case node['platform_family']
  when 'debian'
    package 'drbd8-utils'
  when 'rhel'
    package 'drbd84-utils'
    package 'kmod-drbd84' do
      not_if { node['cloud'] &&
        node['cloud']['provider'] == 'ec2' &&
        node['cloud']['backend_storage_type'] == 'ebs' }
      not_if { platform?('amazon', 'oracle') }
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
      if node['cloud'] && node['cloud']['provider'] == 'ec2' && node['cloud']['backend_storage_type'] == 'ebs'
        filesystem 'ext4'
      end
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

def mount_ebs
  execute 'mount-ebs-volume' do
    command 'mount /dev/mapper/opscode-drbd /var/opt/opscode/drbd/data'
    action :run
    not_if 'mount | grep /dev/mapper/opscode-drbd'
  end
end

def touch_drbd_device
  file '/dev/drbd0' do
    action :create
    owner 'root'
    group 'root'
    mode '0644'
    not_if { ::File.exists?('/dev/drbd0') }
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
