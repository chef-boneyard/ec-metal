require 'cheffish'
require 'chef_metal_vagrant'

harness = data_bag_item 'harness', 'config'
harness_dir = harness['harness_dir']
repo_path   = harness['repo_path']
vms_dir     = harness['vms_dir']

directory vms_dir
vagrant_cluster vms_dir

directory repo_path
with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [File.join(harness_dir, 'cookbooks'),
                     File.join(repo_path, 'cookbooks'),
    File.join(repo_path, 'vendor', 'cookbooks') ]

with_machine_options :vagrant_options => {
  'vm.box' => harness['vagrant_options']['box'],
  'vm.box_url' => harness['vagrant_options']['box_url']
}

# set provisioner options for all of our machines
topo = TopoHelper.new(ec_config: harness['vm_config'])
topo.merged_topology.each do |vmname, config|
  local_provisioner_options = {
    'vagrant_config' => VagrantConfigHelper.generate_vagrant_config(vmname, config, node)
  }

  node.set['harness']['provisioner_options'][vmname] = local_provisioner_options

end
