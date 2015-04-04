# encoding: utf-8

class TopoHelper

  TOPO_TYPES ||= %w(analytics_backends
                  analytics_frontends
                  analytics_standalones
                  analytics_workers
                  backends
                  frontends
                  standalones
                  loadtesters
                )

  attr_accessor :ec_config, :include_layers, :exclude_layers

  # Expected usage:
  # topo = TopoHelper.new(ec_config: node['harness']['vm_config'], exclude_layers: ['analytics'])
  #
  # where vm_config looks like:
  # "layout": {
  #   "topology": "ha",
  #   "api_fqdn": "api.precise.aws",
  #   "manage_fqdn": "manage.precise.aws",
  #   "analytics_fqdn": "analytics.precise.aws",
  #   "configuration": {
  #   },
  #   "backend_vip": {
  #     "hostname": "backend.precise.aws",
  #     "ipaddress": "33.33.13.7",
  #     "device": "eth0",
  #     "heartbeat_device": "eth0"
  #   },
  #   "backends": {
  #     "ip-ub-backend1": {
  #       "hostname": "ip-ub-backend1.precise.aws",
  #       "instance_type": "m3.xlarge",
  #       "ebs_optimized": true,
  #       "bootstrap": true
  #     },
  #     "ip-ub-backend2": {
  #       "hostname": "ip-ub-backend2.precise.aws",
  #       "ebs_optimized": true,
  #       "instance_type": "m3.xlarge"
  #     }
  #   },
  #   "frontends": {
  #     "ip-ub-frontend1": {
  #       "hostname": "ip-ub-frontend1.precise.aws",
  #       "ebs_optimized": true,
  #       "instance_type": "m3.xlarge"
  #     }
  #   },
  #  "analytics": {
  #     "ip-ub-analytics1": {
  #       "hostname": "ip-ub-analytics1.precise.aws",
  #       "ebs_optimized": true,
  #       "instance_type": "m3.xlarge"
  #     }
  #   }
  # }
  def initialize(params = {})
    @ec_config = params[:ec_config] || {} # typically node['harness']['vm_config'] or node['private-chef']
    @include_layers = params[:include_layers] || []
    @exclude_layers = params[:exclude_layers] || []
  end

  def merged_topology
    found_topo_types
      .map { |layer| @ec_config[layer] }
      .reduce({}, :merge)
  end

  def found_topo_types
    TOPO_TYPES.select { |layer| layer_exists?(layer) && include_layer?(layer) }
  end

  def is_backend?(nodename)
    is_topo_type?(nodename, 'backends')
  end

  def is_frontend?(nodename)
    is_topo_type?(nodename, 'frontends')
  end

  def is_analytics_standalones?(nodename)
    is_analytics_topo_type?(nodename, 'analytics_standalones')
  end

  def is_analytics_backends?(nodename)
    is_analytics_topo_type?(nodename, 'analytics_backends')
  end

  def is_analytics_frontends?(nodename)
    is_analytics_topo_type?(nodename, 'analytics_frontends')
  end

  def is_analytics_workers?(nodename)
    is_analytics_topo_type?(nodename, 'analytics_workers')
  end

  def is_analytics?(nodename)
    is_analytics_standalones?(nodename) || is_analytics_backends?(nodename) ||
        is_analytics_frontends?(nodename) || is_analytics_workers?(nodename)
  end


  def is_standalone?(nodename)
    is_topo_type?(nodename, 'standalones')
  end

  def is_topo_type?(nodename, topotype)
    if found_topo_types.include?(topotype)
      return @ec_config[topotype].has_key?(nodename)
    elsif found_topo_types.include?('standalones')
      return @ec_config['standalones'].has_key?(nodename)
    end
    false
  end

  def is_analytics_topo_type?(nodename, topotype)
    if found_topo_types.include?(topotype)
      return @ec_config[topotype].has_key?(nodename)
    end
    false
  end

  def bootstrap_node_name
    bootstrap_node.keys.first
  end

  def bootstrap_host_name
    bootstrap_node.values.first['hostname']
  end

  def bootstrap_host_ip
    bootstrap_node.values.first['ipaddress']
  end

  def bootstrap_node
    if found_topo_types.include?('backends')
      @ec_config['backends']
        .select { |node,attrs| attrs['bootstrap'] == true }
    elsif found_topo_types.include?('standalones')
      @ec_config['standalones']
    end
  end

  def analytics_bootstrap_node_name
    analytics_bootstrap_node.keys.first
  end

  def analytics_bootstrap_host_name
    analytics_bootstrap_node.values.first['hostname']
  end

  def analytics_bootstrap_host_ip
    analytics_bootstrap_node.values.first['ipaddress']
  end

  def analytics_bootstrap_node
    if found_topo_types.include?('analytics_backends')
      @ec_config['analytics_backends']
        .select { |node, attrs| attrs['bootstrap'] == true }
    elsif found_topo_types.include?('analytics_standalones')
      @ec_config['analytics_standalones']
    end
  end

  def mydomainname
    merged_topology
      .values
      .first['hostname']
      .split('.')[1..-1]
      .join('.')
  end

  def myhostname(nodename)
    merged_topology
      .select { |k,v| k == nodename }
      .values
      .first['hostname']
  rescue
    'unknownhost'
  end

  def is_ha?
    @ec_config['topology'] == 'ha' || @ec_config['topology'] == 'customha'
  end

  private

  def layer_exists?(layer)
    @ec_config[layer].is_a?(Hash)
  end

  def include_layer?(layer)
    if @include_layers.length > 0
      return @include_layers.include?(layer)
    end

    if @exclude_layers.length > 0 && @exclude_layers.include?(layer)
      return false
    end

    true # no filters, return true by default
  end
end
