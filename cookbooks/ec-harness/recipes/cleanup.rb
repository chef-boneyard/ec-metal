# encoding: utf-8
include_recipe "ec-harness::vagrant"

node['harness']['vm_config']['backends'].merge(
  node['harness']['vm_config']['frontends']).each do |vmname, config|

  # Bring up our backend machines
  machine vmname do

    action :delete
  end

end

