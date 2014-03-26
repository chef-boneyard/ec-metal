
default['harness']['repo_path'] = ENV['HARNESS_DIR']
default['harness']['vms_dir'] = ::File.join(ENV['HARNESS_DIR'], 'vagrant_vms')
default['harness']['host_cache_path'] = ENV['CACHE_PATH'] || '/oc/EC/Downloads'

default['harness']['vagrant']['box'] = 'opscode-centos-6.5'
default['harness']['vagrant']['box_url'] = 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box'

# Disk 2 size in GBs
default['harness']['vagrant']['disk2_size'] = 2

default['harness']['vm_config'] = {
      installer_file: '/tmp/cache/private-chef-11.1.2-1.el6.x86_64.rpm',
      topology: 'ha',
      api_fqdn: 'api.opscode.piab',
      analytics_fqdn: 'analytics.opscode.piab',
      backend_vip: {
        hostname: 'backend.opscode.piab',
        ipaddress: '33.33.33.20',
        heartbeat_device: 'eth2',
        device: 'eth1'
      },
      backends: {
        backend1: {
          hostname: 'backend1.opscode.piab',
          ipaddress: '33.33.33.21',
          cluster_ipaddress: '33.33.34.5',
          memory: '2048',
          cpus: '2',
          bootstrap: true
        },
        backend2: {
          hostname: 'backend2.opscode.piab',
          ipaddress: '33.33.33.22',
          cluster_ipaddress: '33.33.34.6',
          memory: '2048',
          cpus: '2',
        }
      },
      frontends: {
        frontend1: {
          hostname: 'frontend1.opscode.piab',
          ipaddress: '33.33.33.23',
          memory: '1024',
          cpus: '1',
        }
      },
      virtual_hosts: {
        'private-chef.opscode.piab' => '33.33.33.23',
        'manage.opscode.piab'       => '33.33.33.23',
        'api.opscode.piab'          => '33.33.33.23',
        'analytics.opscode.piab'    => '33.33.33.23',
        'backend.opscode.piab'      => '33.33.33.20',

        'backend1.opscode.piab'     => '33.33.33.21',
        'backend2.opscode.piab'     => '33.33.33.22',
        'frontend1.opscode.piab'    => '33.33.33.23'
      }
    }
