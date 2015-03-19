# encoding: utf-8
# populate all of our machines first, for dynamic name/IP provisioners

include_recipe "ec-harness::#{node['harness']['provider']}"

machine_batch 'cloud_create' do
  action [:converge]
  ecm_topo.merged_topology.each do |vmname, config|

    next if cloud_machine_created?(vmname)
    machine vmname do
      machine_options machine_options_for_provider(vmname, config)
      attribute 'private-chef', privatechef_attributes
      attribute 'root_ssh', node['harness']['root_ssh'].to_hash
      attribute 'cloud', cloud_attributes(node['harness']['provider'])
      recipe 'private-chef::hostname'
      recipe 'private-chef::ec2'
    end
  end
end

# If you're dealing with https://bugzilla.redhat.com/show_bug.cgi?id=1155742
#  and you need a reboot to resize the rootfs, set
#  ec2_options: reboot_wait: true
# in your config.json
if node['harness']['provider'] == 'ec2' &&
  node['harness']['ec2']['reboot_wait'] &&
  node['harness']['ec2']['reboot_wait'] == true

  unless cloud_machine_created?(ecm_topo.bootstrap_node_name)
    sleep_time = 60
    log "Waiting #{sleep_time} seconds for bootstrap node to reboot in case of disk resizing"
    execute 'wait_for_reboots' do
      command "sleep #{sleep_time}"
      action :run
    end
  end
end
