require 'cheffish'
require 'chef_metal_vagrant'

repo_path = node['harness']['repo_path']
vms_dir = node['harness']['vms_dir']

directory vms_dir
vagrant_cluster vms_dir

directory repo_path
with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [ File.join(repo_path, 'cookbooks'),
    File.join(repo_path, 'vendor', 'cookbooks') ]

with_machine_options :vagrant_options => {
  'vm.box' => node['harness']['vagrant']['box'],
  'vm.box_url' => node['harness']['vagrant']['box_url']
}

# set provisioner options for all of our machines
node['harness']['vm_config']['backends'].merge(
  node['harness']['vm_config']['frontends']).each do |vmname, config|

  local_provisioner_options = {
    'vagrant_config' => VagrantConfigHelper.generate_vagrant_config(vmname, config, node)
  }

  node.set['harness']['provisioner_options'][vmname] = local_provisioner_options

end