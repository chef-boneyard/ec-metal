# encoding: utf-8
HOST_CACHE_PATH = node['harness']['host_cache_path']

node['harness']['vm_config']['backends'].each do |backend,config|

  vm_disk2 = ::File.join(node['harness']['vms_dir'], backend, 'disk2.vmdk')
  # This is fucking gross and horrible, make me a library SOON
  vagrant_config = <<-ENDCONFIG
    config.vm.network 'private_network', ip: "#{config['ipaddress']}"
    config.vm.network 'private_network', ip: "#{config['cluster_ipaddress']}"
    config.vm.hostname = "#{config['hostname']}"
    config.vm.synced_folder "#{HOST_CACHE_PATH}", '/tmp/cache'
    config.vm.provider 'virtualbox' do |v|
      v.customize [
        'modifyvm', :id,
        '--name', "#{backend}",
        '--memory', "#{config['memory']}",
        '--cpus', "#{config['cpus']}",
        '--natdnshostresolver1', 'on',
        '--usb', 'off',
        '--usbehci', 'off'
      ]
      v.customize ['createhd',
                  '--filename', "#{vm_disk2}",
                  '--size', 2 * 1024,
                  '--format', 'VMDK']
      v.customize ['storageattach', :id,
                  '--storagectl', 'IDE Controller',
                  '--port', 1,
                  '--device', 0,
                  '--type', 'hdd',
                  '--nonrotational', 'on',
                  '--medium', "#{vm_disk2}"]
    end
  ENDCONFIG

  # Vagrant/HW notes:
  # * it sucks that you have to hardcode "IDE Controller", recent opscode
  #   packer images switched to IDE, but we can't easily detect SATA
  # * virtio network interfaces, in some circumstances, provide MUCH WORSE
  #   performance than good ol' e1000 (the default)
  # * What's the point of the "nonrotational" flag?  tells you the underlying
  #   disk is an SSD.  This should be fine for most of our recent Macs, but I'm
  #   not sure if there's any actual benefit for ext4

  node_attributes = {
    'private-chef' => node['harness']['vm_config'],
    'root_ssh' => node['harness']['root_ssh'].to_hash
  }



  # Bring up our backend machines
  machine backend do

    local_provisioner_options = {
      'vagrant_config' => vagrant_config,
    }
    provisioner_options ChefMetal.enclosing_provisioner_options.merge(local_provisioner_options)

    attributes node_attributes

    recipe 'private-chef::provision'
    recipe 'private-chef::drbd'
    recipe 'private-chef::provision_phase2'

    if node['harness']['vm_config']['backends'][backend]['bootstrap'] == true
      puts "***** Configuring node #{backend} as the bootstrap and primary backend"
    else
      puts "***** Configuring node #{backend} as the standby backend"
    end

    action :create
  end

end

