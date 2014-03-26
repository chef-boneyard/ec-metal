ec-ha
================
This cookbook uses chef-metal to provision, install and upgrade Enterprise Chef HA clusters.

Requirements
------------
* rake
* chef-metal
* Vagrant 1.4 or higher
* Virtualbox

Usage
-----
1. Ensure you have a working recent Vagrant and Virtualbox (tested on Vagrant 1.4.x and 1.5.x)
1. Install chef-metal: https://github.com/opscode/chef-metal
1. To bring up the environment: `rake up`
1. To tear down the environment: `rake destroy`
1. Status: `rake status`
1. SSH: `rake ssh[backend1]`

TODO
----
* This cookbook is still a WIP under heavy development, so far it only proves that chef-metal works :)
* Figure out a nice way to assist with EC package downloads and caching
* Dynamic configuration of environment (OS platform, IPs, storage backends, etc) via config file
* Replication of `/etc/opscode` directory from the bootstrap to the other nodes
* SSH key management inter-node
* pluggable storage backends
* UPGRADES
* ADDONS



Attributes
----------

#### ec-harness::default
Adjust to your needs:
```
default['harness']['repo_path'] = ::File.join(ENV['HOME'], 'chef-repo')
default['harness']['vms_dir'] = ::File.join(node['harness']['repo_path'], 'vagrant_vms')
default['harness']['host_cache_path'] = '/oc/EC/Downloads'

default['harness']['vagrant']['box'] = 'opscode-centos-6.5'
default['harness']['vagrant']['box_url'] = 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box'

# Disk 2 size in GBs
default['harness']['vagrant']['disk2_size'] = 2

default['harness']['vm_config'] = {
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
```



Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Irving Popovetsky
