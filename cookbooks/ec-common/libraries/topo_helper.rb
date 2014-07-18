# encoding: utf-8


class TopoHelper

  TOPO_TYPES = %w(backends frontends standalones analytics)

  def self.merged_topology(vm_config)
    combined_topo = []
    TOPO_TYPES.each do |layer|
      combined_topo << vm_config[layer] if vm_config[layer].is_a?(Hash)
    end

    combined_topo.reduce({}, :merge)
  end

  def self.found_topo_types(vm_config)
    found_topos = []
    TOPO_TYPES.each do |topo|
      found_topos << topo if vm_config.include?(topo)
    end
    found_topos
  end

end