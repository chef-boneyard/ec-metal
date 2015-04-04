# encoding: utf-8

class VagrantConfigHelper

  def self.generate_config(vmname, config, node)
    local_provisioner_options = {
      :vagrant_options => {
        'vm.box' => node['harness']['vagrant']['box'],
        'vm.box_url' => node['harness']['vagrant']['box_url']
      },
      :vagrant_config => generate_vagrant_config(vmname, config, node)
    }
  end

  def self.generate_vagrant_config(vmname, config, node)
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
      config.vm.synced_folder "#{node['harness']['host_cache_path']}", "#{node['harness']['vm_mountpoint']}"
      config.vm.provider 'virtualbox' do |v|
        v.customize [
          'modifyvm', :id,
          '--name', "#{config['hostname']}",
          '--memory', "#{config['memory']}",
          '--cpus', "#{config['cpus']}",
          '--natdnshostresolver1', 'on',
          '--usb', 'off',
          '--usbehci', 'off'
        ]
      end
    ENDCONFIG

    if config['bootstrap'] == true
      vagrant_config += <<-ENDCONFIG
      config.vm.synced_folder "#{File.join(ENV['HARNESS_DIR'], 'users')}", '/srv/piab/users'
      ENDCONFIG
    end

    if node['harness']['vm_config']['topology'] == 'ha' &&
      node['harness']['vm_config']['backends'].include?(vmname)
      vm_disk2 = ::File.join(node['harness']['vms_dir'], vmname, 'disk2.vmdk')
      disk2_size = node['harness']['vagrant']['disk2_size'] || 2
      storage_controller = node['harness']['vagrant']['storage_controller'] || 'IDE Controller'
      vagrant_config += <<-ENDCONFIG
      config.vm.network 'private_network', ip: "#{config['cluster_ipaddress']}"
      config.vm.provider 'virtualbox' do |v|
        v.customize ['createhd',
                    '--filename', "#{vm_disk2}",
                    '--size', #{disk2_size} * 1024,
                    '--format', 'VMDK']
        v.customize ['storageattach', :id,
                    '--storagectl', "#{storage_controller}",
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

end
