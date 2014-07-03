# encoding: utf-8


class TopoHelper

  def self.merged_topology(vm_config)
    combined_topo = []
    %w(backends frontends standalones analytics).each do |layer|
      combined_topo << vm_config[layer] if vm_config[layer].is_a?(Hash)
    end

    combined_topo.reduce({}, :merge)
  end

end