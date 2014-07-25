# encoding: utf-8

class TopoHelper

  TOPO_TYPES = %w(backends frontends standalones analytics)

  attr_accessor :ec_config, :include_layers, :exclude_layers

  def initialize(params = {})
    @ec_config = params[:ec_config] || {} # typically node['harness']['vm_config'] or node['private-chef']
    @include_layers = params[:include_layers] || []
    @exclude_layers = params[:exclude_layers] || []
  end

  def merged_topology
    combined_topo = []
    TOPO_TYPES.each do |layer|
      if layer_exists?(layer) && include_layer?(layer)
        combined_topo << @ec_config[layer]
      end
    end

    combined_topo.reduce({}, :merge)
  end

  def found_topo_types
    found_topos = []
    TOPO_TYPES.each do |layer|
      if layer_exists?(layer) && include_layer?(layer)
        found_topos << layer
      end
    end
    found_topos
  end

  def is_backend?(nodename)
    if found_topo_types.include?('backends')
      return true if @ec_config['backends'].has_key?(nodename)
    end
    false
  end

  def is_frontend?(nodename)
    if found_topo_types.include?('frontends')
      return true if @ec_config['frontends'].has_key?(nodename)
    end
    false
  end

  def bootstrap_node_name
    if found_topo_types.include?('backends')
      @ec_config['backends']
        .select { |node,attrs| attrs['bootstrap'] == true }
        .keys
        .first
    elsif found_topo_types.include?('standalones')
      @ec_config['standalones'].keys.first
    end
  end

  def bootstrap_host_name
    if found_topo_types.include?('backends')
      @ec_config['backends']
        .select { |node,attrs| attrs['bootstrap'] == true }
        .values
        .first['hostname']
    elsif found_topo_types.include?('standalones')
      @ec_config['standalones'].values.first['hostname']
    end
  end

  private

  def layer_exists?(layer)
    return true if @ec_config[layer].is_a?(Hash)
    false
  end

  def include_layer?(layer)
    if @include_layers.length > 0
      if @include_layers.include?(layer)
        return true
      else
        return false
      end
    end

    if @exclude_layers.length > 0 && @exclude_layers.include?(layer)
      return false
    end

    true # no filters, return true by default
  end

end