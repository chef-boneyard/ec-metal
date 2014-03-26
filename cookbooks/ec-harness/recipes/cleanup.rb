# encoding: utf-8
include_recipe "ec-harness::vagrant"

node['harness']['vm_config']['backends'].each do |backend,config|

  # Bring up our backend machines
  machine backend do

    action :delete
  end

end

