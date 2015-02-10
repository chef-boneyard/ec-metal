# (More) In Depth Guide
## Setting up ec-metal

1. `git clone https://github.com/opscode/ec-metal.git`
1. Decide whether you are going to use the ec2 or vagrant provider
	- ec2 is recommended
1. Create a config.json
	- Review sections below to customize your config to support the Chef Server variant being installed
1. Check out the ec-metal docs for more info
	- [https://github.com/opscode/ec-metal#toc](https://github.com/opscode/ec-metal#toc)

## Using ec-metal to install Chef Server

`ec-metal` is operated through the use of `rake` tasks and acts upon a `json` configuration file.

Setting up and running can take upwards of **50 MINUTES**, likely more. **This process is not quick.** Expect for it to take you more than your first attempt to get `ec-metal` running.

Using `ec-metal` will require 4 things at minimum, having:

- provider specific prerequisites met
- appropriate environmental variables set and
- a valid configuration file
- a local or remote source for packages

#### Provider Specific Prereqs
- Vagrant
	- ensure that recent versions of `Vagrant` & `Virtualbox` are installed
	- desired `CPU` and `memory` settings
	- (optional) have the desired `.box file` added using `vagrant box add`
- EC2
	- You will need to know:
		- a `subnet` within the desired availability zone
		- an `AMI` of the desired platform/version in the same AZ
		- desired `instance types` (probably `m3.medium` for frontends and `c3.xlarge` for backends)
		- (optional) use a VPC/subnet with access to the `Chef VPN` -- and therefore access to Artifactory

#### Environmental Variables
**NOTE**: When specifying file paths, you'll have less headache by providing absolute paths.

- `ECM_CONFIG`: the path to a file .json containing your dc-metal configuration options
	- "export ECM_CONFIG=/tmp/tier-private_chef-ubuntu-12.04-vagrant.json"
- `ECM_CACHE_PATH`: a path to a directory where ec-metal will look for packages specific in your config file
	- "export ECM_CACHE_PATH=~/Downloads"
- `ECM_CHEF_REPO`: a path to a directory where ec-metal will build the `chef-repo` to use with `chef-metal`
	- "export ECM_CHEF_REPO=/tmp/ecm-chef-repo"
- (ec2 only) `ECM_KEYPAIR_PATH`: a path to a directory where generated .pem keys will be saved/retrieved
	- "export ECM_KEYPAIR_PATH=~/.ec-metal"
- (ec2 only) `ECM_KEYPAIR_NAME`: the name to use when uploading said .pem keys to EC2
	- "export ECM_KEYPAIR_NAME=aaa-isa-us-west-2-yay"
	
#### Configuration 
The config for `ec-metal` is in the .json format and must resemble the examples at the bottom of this document.
There are also a few top-level options, such as `"run_pedant": true` that you can use. See [examples](https://github.com/opscode/ec-metal/tree/master/examples).

**Required** `"default_package": "/path/to/chef_server_package_file.deb"`

**addons** 
Other packages (for addons and else)can be specified within the configuration file. See [https://github.com/opscode/ec-metal#setting-packages-for-installation-and-upgrades](https://github.com/opscode/ec-metal#setting-packages-for-installation-and-upgrades)

Of note are the provider specific options:

**EC2** -- This is where you will need the `subnet`, `AMI`, and `instance type` information:

```
"provider": "ec2",
 "ec2_options": {
   "region": "us-west-2",
   "vpc_subnet": "subnet-XXXXXXXX",
   "ami_id": "ami-XXXXXXXX",
   "ssh_username": "ubuntu",
   "use_private_ip_for_ssh": false,
   "ec_metal_tag" : "EcMetal key will default to no value if attribute is omitted"
```

**Vagrant** -- You will need to know your desired `CPU`, `memory`, and a URL for a `.box file` (probably from [Bento](http://github.com/opscode/bento))

```
  "vagrant_options": {
    "box": "opscode-ubuntu-12.04",
    "box_url": "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box",
    "disk2_size": "2"
```

#### Packages
There's several places you can get package for the various interations of the chef server. Below are some example permalinks **which can all be tweaked to get your desired platofrm/version**.

**Chef Server 12** (from [packagecloud](http://packagecloud.io/chef/stable/)):

```
https://packagecloud.io/chef/stable/download?distro=lucid&filename=chef-server-core_12.0.0-rc.5-1_amd64.deb
```

**Private Chef** (from S3):

```
https://s3.amazonaws.com/opscode-private-chef/el/6/x86_64/private-chef-11.2.4-1.el6.x86_64.rpm
https://s3.amazonaws.com/opscode-private-chef/el/6/x86_64/opscode-manage-1.6.2-1.el6.x86_64.rpm
https://s3.amazonaws.com/opscode-private-chef/el/6/x86_64/opscode-push-jobs-server-1.1.3-1.el6.x86_64.rpm
https://s3.amazonaws.com/opscode-private-chef/el/6/x86_64/opscode-reporting-1.1.6-1.x86_64.rpm

```

**Open Source Chef Server** (from Omnitruck):

```
https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.1.6-1_amd64.deb
```

##Make it go!
After you have all the pieces in place:

```
rake up
```

##Troubleshooting

#### Converge will fail and you should get error
```
 * package[chef-server-core] action install[2014-10-20T15:02:56+00:00] INFO: Processing package[chef-server-core] action install (private-chef::provision line 27)

                        * Package chef-server-core not found: /tmp/ecm_cache/chef-server-core
                        ================================================================================
                        Error executing action `install` on resource 'package[chef-server-core]'
                        ================================================================================

                        Chef::Exceptions::Package
                        -------------------------
                        Package chef-server-core not found: /tmp/ecm_cache/chef-server-core
```

#### Installing Chef 12
* Once installed complete the instructions here to complete the process for Cher Server and the addons.
http://docs.getchef.com/server/install_server.html

#### Setting up Key Pairs for ec-metal
The way ec-metal previously generated ec2 key pairs commonly caused naming conflicts. To get around that ec-metal would attempt to generate key for each user and git clone. This became difficult to manage and started to create key clutter in ec2.  

Follow these steps to create a reusable, throwaway key for testing with ec-metal:

```
# create a sub-dir somewhere that will only contain new ssh keys. 
# Recommended not to use your personal ssh keys!
mkdir ~/.ec-metal

cd ~/.ec-metal

ssh-keygen -f id_rsa
```

the generated keys may need to be copied to ec-metal/chef-repo/keys if the files don’t properly symlink during execution

### Running ec-metal
When using the ec2 provider you must specify two env vars:
* ECM_KEYPAIR_PATH=path to the generated ssh keys for testing
* ECM_KEYPAIR_NAME=key name to be created in ec2 (once created it ec-metal will reuse the key pair)

```
$ ECM_KEYPAIR_NAME=myname-ec-metal ECM_KEYPAIR_PATH=~/.ec-metal rake up
```

### Debugging
* Add “debug” to the rake command for chef-client debug output
* Login ```ssh -i chef-repo/keys/id_rsa (ubuntu|root)@public_ip```

### Upgrading to CS12
* Do it the old fashioned way: http://docs.getchef.com/server/upgrade_server.html
* Report any errors found in the the documentation.

### Clean up
```bash
# blow it all away
$ rake destroy
```

## ec-metal Configuration Examples
### ec2 options
#### region
us-west-2
  
#### VPC
* select your own IP.  ec-metal doesn't use EIP so happy hunting!
* make sure you use a subnet that matches the AZ of your instances.

#### ec2-cs12-tier
```json
{
 "provider": "ec2",
 "ec2_options": {
   "region": "us-west-2",
   "vpc_subnet": "subnet-XXXXXXXX",
   "ami_id": "ami-XXXXXXXX",
   "ssh_username": "ubuntu",
   "use_private_ip_for_ssh": false
 },
 "default_package": "chef-server-core",
 "layout": {
   "topology": "tier",
   "api_fqdn": "api.ubuntu.ec2",
   "manage_fqdn": "manage.ubuntu.ec2",
   "analytics_fqdn": "analytics.ubuntu.ec2",
   "backends": {
     "backend1": {
       "hostname": "backend1.ubuntu.ec2",
       "instance_type": "c3.xlarge",
       "ebs_optimized": true,
       "bootstrap": true
     }
   },
   "frontends": {
     "frontend1": {
       "hostname": "frontend1.ubuntu.ec2",
       "ebs_optimized": false,
       "instance_type": "m3.medium"
     }
   }
 }
}
```

#### ec2-ha-ec
```json
{
 "provider": "ec2",
 "ec2_options": {
 },
 "default_package": "URL",
 "layout": {
   "topology": "ha",
   "api_fqdn": "api.ubuntu.ec2",
   "manage_fqdn": "manage.ubuntu.ec2",
   "analytics_fqdn": "analytics.ubuntu.ec2",
   "backend_vip": {
     "hostname": "backend_vip.ubuntu.ec2",
     "ipaddress": "33.33.33.XX",
     "device": "eth0",
     "heartbeat_device": "eth0"
   },
   "backends": {
     "backend1": {
       "hostname": "backend1.ubuntu.ec2",
       "instance_type": "c3.xlarge",
       "ebs_optimized": true,
       "bootstrap": true
     },
     "backend2": {
       "hostname": "backend2.ubuntu.ec2",
       "ebs_optimized": true,
       "instance_type": "c3.xlarge"
     }
   },
   "frontends": {
     "frontend1": {
       "hostname": "frontend1.ubuntu.ec2",
       "ebs_optimized": false,
       "instance_type": "m3.medium"
     }
   }
 }
}
```

#### ec2-sa-cs12
```json
{
 "provider": "ec2",
 "ec2_options": {
   "region": "us-west-2",
   "vpc_subnet": "subnet-XXXXXXXX",
   "ami_id": "ami-XXXXXXXX",
   "ssh_username": "ubuntu",
   "use_private_ip_for_ssh": false
 },
 "default_package": "chef-server-core",
 "layout": {
   "topology": "standalone",
   "api_fqdn": "api.ubuntu.ec2",
   "manage_fqdn": "manage.ubuntu.ec2",
   "analytics_fqdn": "analytics.ubuntu.ec2",
   "standalones": {
     "standalone1": {
       "hostname": "standalone1.ubuntu.ec2",
       "instance_type": "c3.xlarge",
       "ebs_optimized": true
     }
   }
 }
}
```

#### ec2-tier-cs12
```json
{
 "provider": "ec2",
 "ec2_options": {
   "region": "us-west-2",
   "vpc_subnet": "subnet-XXXXXXXX",
   "ami_id": "ami-XXXXXXXX",
   "ssh_username": "ubuntu",
   "use_private_ip_for_ssh": false
 },
 "default_package": "chef-server-core",
 "layout": {
   "topology": "tier",
   "api_fqdn": "api.ubuntu.ec2",
   "manage_fqdn": "manage.ubuntu.ec2",
   "analytics_fqdn": "analytics.ubuntu.ec2",
   "backend_vip": {
     "hostname": "backend_vip.ubuntu.ec2",
     "ipaddress": "33.33.33.XX",
     "device": "eth0",
     "heartbeat_device": "eth0"
   },
   "backends": {
     "backend1": {
       "hostname": "backend1.ubuntu.ec2",
       "instance_type": "c3.xlarge",
       "ebs_optimized": true,
       "bootstrap": true
     }
   },
   "frontends": {
     "frontend1": {
       "hostname": "frontend1.ubuntu.ec2",
       "ebs_optimized": false,
       "instance_type": "m3.medium"
     }
   }
 }
}
```

#### ec2-standalone-osc
```json
{
 "provider": "ec2",
"ec2_options": {
   "region": "us-west-2",
   "vpc_subnet": "subnet-XXXXXXXX",
   "ami_id": "ami-XXXXXXXX",
   "ssh_username": "ubuntu",
   "use_private_ip_for_ssh": false
 },
 "default_package": "URL",
 "osc_install": true,
 "layout": {
   "topology": "standalone",
   "api_fqdn": "api.ubuntu.ec2",
   "manage_fqdn": "manage.ubuntu.ec2",
   "analytics_fqdn": "analytics.ubuntu.ec2",
   "standalones": {
     "standalone1": {
       "hostname": "standalone1.ubuntu.ec2",
       "instance_type": "c3.xlarge",
       "ebs_optimized": true
     }
   }
 }
}
```

#### vagrant-tiered-ec
```json
{
  "provider":"vagrant",
  "vagrant_options": {
    "box": "opscode-centos-6.5",
    "disk2_size": "2",
    "box_url": "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box"
  },
  "default_package": "ec/private-chef/el/6/x86_64/private-chef-11.2.2-1.el6.x86_64.rpm",
  "manage_package": "ec/opscode-manage/el/6/x86_64/opscode-manage-1.5.4-1.el6.x86_64.rpm",
  "packages": {
  },
  "layout": {
    "topology": "tier",
    "api_fqdn": "api65.centos.vagrant",
    "default_orgname": null,
    "manage_fqdn": "manage65.centos.vagrant",
    "backends": {
      "backend0": {
        "hostname": "backend065.centos.vagrant",
        "memory": "2560",
        "cpus": "2",
        "ipaddress": "33.30.33.21",
        "cluster_ipaddress": "33.30.34.5",
        "bootstrap": true
      }
    },
    "frontends": {
      "frontend0": {
        "hostname": "frontend065.centos.vagrant",
        "memory": "1024",
        "cpus": "1",
        "ipaddress": "33.30.33.22"
      }
    },
    "backend_vip": {
      "hostname": "backend065.centos.vagrant",
      "ipaddress": "33.30.33.21",
      "device": "eth0",
      "heartbeat_device": "eth1"
    },
    "virtual_hosts": {
      "private-chef65.centos.vagrant": "33.30.33.22",
      "manage65.centos.vagrant": "33.30.33.22",
      "api65.centos.vagrant": "33.30.33.22",
      "backend65.centos.vagrant": "33.30.33.21",
      "backend065.centos.vagrant": "33.30.33.21",
      "frontend065.centos.vagrant": "33.30.33.22"
    }
  }
}
```

### analytics
### standalone
```json
 "analytics_standalones": {
      "analytics-standalone1": {
        "hostname": "analytics-standalone.ubuntu.ec2",
         "instance_type": "m3.medium",
       "ebs_optimized": true
        "bootstrap": true
      }
    },
```
