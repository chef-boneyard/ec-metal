# encoding: utf-8

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class WaitForHaMaster < Chef::Resource::LWRPBase
      self.resource_name = :wait_for_ha_master
      actions :create
      default_action :create
    end
  end
end

require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class WaitForHaMaster < Chef::Provider::LWRPBase
      use_inline_resources

      action :create do
        topology = TopoHelper.new(ec_config: node['private-chef'])
        wait_for_ha_master if topology.is_ha?
      end

      def wait_for_ha_master
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
  end
end