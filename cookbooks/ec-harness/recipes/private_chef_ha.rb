# encoding: utf-8

bootstrap_node_name =
  node['harness']['vm_config']['backends'].select { |node,attrs| attrs['bootstrap'] == true }.keys.first

# Bring the backends and frontends online
node['harness']['vm_config']['backends'].merge(
  node['harness']['vm_config']['frontends']).each do |vmname, config|

  node_attributes = {
    'private-chef' => node['harness']['vm_config'],
    'root_ssh' => node['harness']['root_ssh'].to_hash
  }

  # provisoner_options is set by your provisioner recipe (ex: vagrant.rb)
  with_provisioner_options node['harness']['provisioner_options'][vmname]

  machine vmname do

    attributes node_attributes

    recipe 'private-chef::hostsfile'
    recipe 'private-chef::provision'
    recipe 'private-chef::drbd' if node['harness']['vm_config']['backends'].include?(vmname)
    recipe 'private-chef::provision_phase2'
    recipe 'private-chef::users' if vmname == bootstrap_node_name

    action :create
  end
end
