# (More) In Depth Guide

## Using ec-metal to install Chef Server
### ec-metal setup
1. git clone https://github.com/opscode/ec-metal.git
1. Decide whether you are going to use the ec2 or vagrant provider
 1. ec2 is recommended
1. Create a config.json
 1. Starter configuration examples
 1. Review sections below to customize your config to support the Chef Server variant being installed
1. Check out the ec-metal docs for more info
 1. https://github.com/opscode/ec-metal#toc

### EC
*private-chef* packages
#### addons
* When selecting addons to install refer to https://github.com/opscode/ec-metal#setting-packages-for-installation-and-upgrades
.  The value will be the URL or file path based on provider.

Packages examples
EC example
analytics example

### OSC
*chef-server* packages for open source
* *set osc_install to true*

OSC example

### CS12
*chef-server-core* packages
* ec-metal does not officially support CS12.  However, ec-metal will get you most of the way there to the point where the CS12 installation documentation can be followed.
* *set default_package to chef-server-core*

CS12 examples
analytics example

#### Converge will fail and you should get error
```bash
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
* Install - https://packagecloud.io/chef/stable/
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
