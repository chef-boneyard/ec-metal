
action :drbd do
  install_drbd_packages
  create_drbd_dirs
  create_lvm([disk_devmap[1]]) # assume drbd volume is the second disk (ephemeral)
  create_drbd_config_files
  setup_drbd
  touch_drbd_ready
  new_resource.updated_by_last_action(true)
end

action :ebs_shared do
  install_drbd_packages # Needed because of raise in opscode-omnibus drbd.rb
  create_drbd_dirs
  if topology.bootstrap_node_name == node.name
    attach_ebs_volume
    create_lvm([disk_devmap[3]]) # assume drbd/ebs volume is the fourth disk (/dev/sdd)
    mount_ebs
    save_ebs_volumes_db
  else
    set_ebs_volume_on_standby
  end
  touch_drbd_device # stupid hack to trick ha-status into being OK
  touch_drbd_ready
  new_resource.updated_by_last_action(true)
end

action :ebs_standalone do
  attach_ebs_volume
  create_lvm(disk_devmap[3], '/var/opt/opscode') # assume drbd/ebs volume is the fourth disk (/dev/sdd)
  save_ebs_volumes_db
  create_drbd_dirs
  touch_drbd_ready
  new_resource.updated_by_last_action(true)
end

action :ebs_save_databag do
  save_ebs_volumes_db
end

action :set_ebs_volume_node_attribute do
  set_ebs_volume_on_standby
end

def topology
  TopoHelper.new(ec_config: node['private-chef'])
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
        TopoHelper.new(ec_config: node['private-chef']).bootstrap_host_name
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
  item = data_bag_item('ebs_volumes_db', topology.bootstrap_host_name)
  item['volume_id']
end

def create_ebs_volume
  aws_ebs_volume topology.bootstrap_host_name do
    aws_access_key node['cloud']['aws_access_key_id']
    aws_secret_access_key node['cloud']['aws_secret_access_key']
    size node['cloud']['ebs_disk_size'].to_i
    device '/dev/sdd'
    if node['cloud']['ebs_use_piops'] == true
      volume_type 'io1'
      piops_val = node['cloud']['ebs_disk_size'].to_i * 30
      piops_val = 4000 if piops_val > 4000
      piops piops_val
    else
      volume_type 'gp2'
    end
    action [ :create, :attach ]
  end
end

def rootdev
  node.filesystem.select { |k,v| v['mount'] == '/' }.keys.first
end

# Return array of disk devices, so we can use first, second, third, etc
def disk_devmap
  if rootdev =~ /xvda/
    diskmap = %w(xvda xvdb xvdc xvdd xvde xvdf xvdg)
  elsif rootdev =~ /xvde/
    diskmap = %w(xvde xvdf xvdg xvdh xvdi xvdj xvdk)
  elsif node['platform_family'] == 'rhel' &&
    node['platform_version'].to_i == 5 &&
    ! ::File.exists?('/dev/sda')
    diskmap = ::Dir.entries('/proc/ide').reject { |a| a =~ /ide/ || a =~ /drivers/ || a =~ /\./  }.sort
  else
    diskmap = %w(sda sdb sdc sdd sde sdf sdg)
  end
  diskmap.map { |disk| "/dev/#{disk}"  }
end

def attach_ebs_volume
  begin
    ebs_volumes_db = data_bag('ebs_volumes_db')
  rescue Exception
    create_ebs_volumes_db
    ebs_volumes_db = data_bag('ebs_volumes_db')
  end

  unless ebs_volumes_db.include?(topology.bootstrap_host_name)
    create_ebs_volume
  else
    aws_ebs_volume topology.bootstrap_host_name do
      aws_access_key node['cloud']['aws_access_key_id']
      aws_secret_access_key node['cloud']['aws_secret_access_key']
      volume_id get_ebs_volumes_db
      device '/dev/sdd'
      action :attach
    end
  end
end

def set_ebs_volume_on_standby
  node.set['aws']['ebs_volume'][topology.bootstrap_host_name]['volume_id'] = get_ebs_volumes_db
  node.save
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

      # Ugh, very annoying elrepo packaging issue with drbd
      if node['platform_version'].to_f >= 6.0 && node['platform_version'].to_f < 6.6
        version '8.4.5-1.el6.elrepo'
      end
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

def fstype
  if node['platform_family'] == 'debian' || node['platform'] == 'centos'
    package 'xfsprogs'
    'xfs'
  elsif system('which mkfs.ext4')
    'ext4'
  else
    'ext3'
  end
end


def create_lvm(disks, mountpoint = nil)
  stupid_chown_trick = false
  if mountpoint && !Dir.exists?(mountpoint)
    # stupid trick to make sure the partybus migration-level stuff still triggers
    # until a better fix for OC-11297 has been developed
    # essentially use a different mode
    # Note, lvm cookbook is dumb and resets this, so do it later on
    stupid_chown_trick = true
  end

  fs_type = fstype
  lvm_volume_group 'opscode' do
    physical_volumes disks

    logical_volume 'drbd' do
      size        '80%VG'
      if node['cloud'] && node['cloud']['provider'] == 'ec2' && node['cloud']['backend_storage_type'] == 'ebs'
        filesystem fs_type
      end
      # Only let lvm create/manage the mountpoint for standalone/tier servers
      mount_point mountpoint if mountpoint
      stripes disks.length if disks.is_a?(Array)
    end
  end

  if stupid_chown_trick == true
    directory mountpoint do
      mode '0775'
      action :create
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
  execute 'create-md' do
    command 'yes yes | drbdadm create-md pc0'
    action :run
    if running_lucid?
      only_if 'drbdadm dump-md pc0 2>&1 | grep "exited with code 255"'
    else
      only_if 'drbdadm dump-md pc0 2>&1 | grep "No valid meta data"'
    end
    notifies :run, 'execute[drbdadm-up]', :immediately unless node['platform_family'] == 'debian'
  end

  if node['platform_family'] == 'debian'
    execute 'start-drbd-service-with-timeout' do
      command 'service drbd start'
      not_if "lsmod | grep drbd"
      if running_lucid?
        notifies :run, "execute[drbdadm-disconnect]", :immediately
      else
        notifies :run, "execute[drbd-primary-force]", :immediately
      end
    end

    # Ubuntu 10.04 specific
    execute 'drbdadm-disconnect' do
      action :nothing
      command 'drbdadm disconnect pc0'
      notifies :run, "execute[drbdadm-detach]", :immediately
    end
    execute 'drbdadm-detach' do
      action :nothing
      command 'drbdadm detach pc0'
      notifies :run, "execute[drbdadm-up-10.04]", :immediately
    end
    # why can't I notify execute[drbdadm-up]? - resource not found
     execute 'drbdadm-up-10.04' do
      action :nothing
      command 'drbdadm up pc0'
      notifies :run, "execute[drbd-primary-force]", :immediately
    end
  else
    execute 'drbdadm-up' do
      command 'drbdadm up pc0'
      action :nothing
      notifies :run, "execute[drbd-primary-force]", :immediately
    end
  end

  # TODO: more reliably detect if we are an unconfigured bootstrap node
  execute 'drbd-primary-force' do
    if node['platform_family'] == 'debian'
      command 'drbdadm -- --overwrite-data-of-peer primary pc0'
    else
      command 'drbdadm primary --force pc0'
    end
    action :nothing
    notifies :run, 'execute[mkfs-drbd-volume]', :immediately
    only_if { node['private-chef']['backends'][node.name]['bootstrap'] == true }
    not_if { ::File.exists?(::File.join(DRBD_DIR, 'drbd_ready')) }
  end

  execute 'mkfs-drbd-volume' do
    command "mkfs.#{fstype} /dev/drbd0"
    action :nothing
    notifies :run, 'execute[mount-drbd-volume]', :immediately
    not_if "file -sL /dev/drbd0 | grep #{fstype}"
  end

  execute 'mount-drbd-volume' do
    command 'mount /dev/drbd0 /var/opt/opscode/drbd/data'
    action :nothing
    not_if 'mount | grep /dev/drbd0'
  end
end

def mount_ebs
  mountpoint = '/var/opt/opscode/drbd/data'
  execute 'mount-ebs-volume' do
    command "mount /dev/mapper/opscode-drbd #{mountpoint}"
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

def running_lucid?
  node['platform'] == 'ubuntu' && node['platform_version'].to_i == 10
end
