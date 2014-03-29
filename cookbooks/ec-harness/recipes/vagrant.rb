require 'cheffish'
require 'chef_metal/vagrant'

repo_path = node['harness']['repo_path']
vms_dir = node['harness']['vms_dir']

directory vms_dir
vagrant_cluster vms_dir

directory repo_path
with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [ File.join(repo_path, 'cookbooks'),
    File.join(repo_path, 'vendor', 'cookbooks') ]

vagrant_box node['harness']['vagrant']['box'] do
  url node['harness']['vagrant']['box_url']
end