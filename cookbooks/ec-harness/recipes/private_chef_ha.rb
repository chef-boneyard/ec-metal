# encoding: utf-8

# This is fucking gross and horrible, make me a library SOON
def generate_vagrant_config(vmname, config)
  # Vagrant/Virtualbox notes:
  # * it sucks that you have to hardcode "IDE Controller", recent opscode
  #   packer images switched to IDE, but we can't easily detect SATA
  # * virtio network interfaces, in some circumstances, provide MUCH WORSE
  #   performance than good ol' e1000 (the default)
  # * What's the point of the "nonrotational" flag?  tells you the underlying
  #   disk is an SSD.  This should be fine for most of our recent Macs, but I'm
  #   not sure if there's any actual benefit for ext4

  vagrant_config = <<-ENDCONFIG
    config.vm.network 'private_network', ip: "#{config['ipaddress']}"
    config.vm.hostname = "#{config['hostname']}"
    config.vm.synced_folder "#{node['harness']['host_cache_path']}", '/tmp/cache'
    config.vm.provider 'virtualbox' do |v|
      v.customize [
        'modifyvm', :id,
        '--name', "#{vmname}",
        '--memory', "#{config['memory']}",
        '--cpus', "#{config['cpus']}",
        '--natdnshostresolver1', 'on',
        '--usb', 'off',
        '--usbehci', 'off'
      ]
    end
  ENDCONFIG

  if node['harness']['vm_config']['backends'].include?(vmname)
    vm_disk2 = ::File.join(node['harness']['vms_dir'], vmname, 'disk2.vmdk')
    vagrant_config += <<-ENDCONFIG
    config.vm.network 'private_network', ip: "#{config['cluster_ipaddress']}"
    config.vm.provider 'virtualbox' do |v|
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
  end
  vagrant_config
end


# Bring the backends and frontends online
node['harness']['vm_config']['backends'].merge(
  node['harness']['vm_config']['frontends']).each do |vmname, config|

  node_attributes = {
    'private-chef' => node['harness']['vm_config'],
    'root_ssh' => node['harness']['root_ssh'].to_hash
  }

  vagrant_config = generate_vagrant_config(vmname, config)

  machine vmname do
    local_provisioner_options = {
      'vagrant_config' => vagrant_config,
    }
    provisioner_options ChefMetal.enclosing_provisioner_options.merge(local_provisioner_options)

    attributes node_attributes

    recipe 'private-chef::provision'
    recipe 'private-chef::drbd' if node['harness']['vm_config']['backends'].include?(vmname)
    recipe 'private-chef::provision_phase2'

    action :create
  end
end
