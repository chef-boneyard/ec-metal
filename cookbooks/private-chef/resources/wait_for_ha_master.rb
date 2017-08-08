resource_name :wait_for_ha_master
property :name, String

action :create do
  topology = TopoHelper.new(ec_config: node['private-chef'])
  Chef::Log.info("[wait_for_ha_master] going in to wait loop because is_ha? is #{topology.is_ha?}")
  wait_loop if topology.is_ha?
end

action_class do
  def wait_loop
    Chef::Log.info('Waiting for node to become HA master')
    attempts = 600
    STDOUT.sync = true

    keepalived_dir = '/var/opt/opscode/keepalived'
    requested_cluster_status_file = ::File.join(keepalived_dir, 'requested_cluster_status')
    cluster_status_file = ::File.join(keepalived_dir, 'current_cluster_status')

    (0..attempts).each do |attempt|
      break if ::File.exists?(requested_cluster_status_file) &&
        ::File.open(requested_cluster_status_file).read.chomp == 'master' &&
        ::File.exists?(cluster_status_file) &&
        ::File.open(cluster_status_file).read.chomp == 'master'

      sleep 1
      print '.'
      if attempt == attempts
        raise "Gave up waiting for HA master state after #{attempt} attempts"
      end
    end
  end
end
