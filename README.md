ec-ha
================
This tool uses chef-metal to provision, install and upgrade Enterprise Chef HA clusters.

TOC
---
{:toc}

Requirements
------------
* rake
* chef-metal
* Vagrant 1.5 or higher
* Virtualbox

Goals of this project
---------------------
1. Demonstrate the capabilities and (hopefully) best practices of chef-metal
1. Enable Chef QA and Dev teams to test various EC topologies and packages in install and upgrade scenarios
1. Enable Chef customers to deploy and upgrade Enterprise Chef without runbooks

Usage
-----
1. Ensure you have a working recent Vagrant and Virtualbox (tested on Vagrant 1.5.x)
1. Install dependent gems into `vendor/bundle`: `rake bundle`
1. Copy `config.json.example` to `config.json` and adjust as needed
  * the `default_package` attribute is used in install and upgrade steps
1. Download the private-chef packages to the ec-ha/cache directory or point to your own installer cache with `$CACHE_PATH`
1. To bring up the environment: `rake up`
1. To upgrade a running environment, set a new `default_package` attribute and run: `rake upgrade`
1. To tear down the environment: `rake destroy`
1. The Upgrade Torture Test: `rake upgrade_torture`
  1. Brings the environment online
  1. installs/upgrades all of the packages defined in the `packages` attribute
1. Status: `rake status`
1. SSH: `rake ssh[backend1]`
1. the `clients`, `nodes`, `keys` and `vagramt_vms` subdirectories are created automatically

TODO
----
NOTE: This is still a WIP under heavy development
* Figure out a nice way to assist with EC package downloads and caching (dendrite?)
* Testing
* Ubuntu support (12.04 and 14.04)
* Ability to drive installation, upgrade and restore-from-backup on already-provisioned servers (ex: customer environments) possibly using: https://github.com/double-z/chef-metal-ssh
* EC2 improvements
  - Switch to using EC2 IAM roles to avoid slinging aws keys around.
    + Rake Tasks to auto-create IAM Roles
  - Rake Task to auto-create the VPC networking
  - Creation of ELB (load balancers) and auto-add frontends to the ELB
  - Optional use of EBS storage (without DRBD) that is handed over during backend node failover
  - rake ssh to find and connect you to your AWS instances


Attributes
----------
All relevant attributes should now be controlled through the config.json file

#### config.json.example - Vagrant provisioning
```
{
  "provider": "vagrant",
  "vagrant_options": {
    "box": "opscode-centos-6.5",
    "box_url": "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box",
    "disk2_size": "2"
  },
  "default_package": "private-chef-11.1.2-1.el6.x86_64.rpm",
  "manage_package": "opscode-manage-1.3.0-1.el6.x86_64.rpm",
  "reporting_package": "opscode-reporting-1.1.0-1.el6.x86_64.rpm",
  "pushy_package": "opscode-push-jobs-server-1.1.0-1.el6.x86_64.rpm",
  "packages": {
    "PC1.2": "private-chef-1.2.8.2-1.el6.x86_64.rpm",
    "PC1.4": "private-chef-1.4.6-1.el6.x86_64.rpm",
    "EC11.0": "private-chef-11.0.2-1.el6.x86_64.rpm",
    "EC11.1": "private-chef-11.1.2-1.el6.x86_64.rpm"
  },
  "layout": {
    "topology": "ha",
    "api_fqdn": "api.opscode.piab",
    "manage_fqdn": "manage.opscode.piab",
    "analytics_fqdn": "analytics.opscode.piab",
    "backend_vip": {
      "hostname": "backend.opscode.piab",
      "ipaddress": "33.33.33.20",
      "heartbeat_device": "eth2",
      "device": "eth1"
    },
    "backends": {
      "backend1": {
        "hostname": "backend1.opscode.piab",
        "ipaddress": "33.33.33.21",
        "cluster_ipaddress": "33.33.34.5",
        "memory": "2560",
        "cpus": "2",
        "bootstrap": true
      },
      "backend2": {
        "hostname": "backend2.opscode.piab",
        "ipaddress": "33.33.33.22",
        "cluster_ipaddress": "33.33.34.6",
        "memory": "2560",
        "cpus": "2"
      }
    },
    "frontends": {
      "frontend1": {
        "hostname": "frontend1.opscode.piab",
        "ipaddress": "33.33.33.23",
        "memory": "1024",
        "cpus": "1"
      }
    },
    "virtual_hosts": {
      "private-chef.opscode.piab": "33.33.33.23",
      "manage.opscode.piab": "33.33.33.23",
      "api.opscode.piab": "33.33.33.23",
      "analytics.opscode.piab": "33.33.33.23",
      "backend.opscode.piab": "33.33.33.20",
      "backend1.opscode.piab": "33.33.33.21",
      "backend2.opscode.piab": "33.33.33.22",
      "frontend1.opscode.piab": "33.33.33.23"
    }
  }
}
```


Running at AWS
---------------


Prerequisites:
* Write out an .aws/config file as described here: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#d0e726
* Get yourself a CentOS 6.5 AMI https://aws.amazon.com/marketplace/ordering?productId=f4325b48-37b0-405a-9847-236c64622e3e&ref_=dtl_psb_continue&region=us-east-1
  * HIGHLY RECOMMENDED: Build your own AMI based off the CentOS image with patches applied (heartbleed) and chef package installed
* Get yourself a VPC that has a "Public" Subnet with an Internet Gateway, and VPC security groups that allow inbound SSH and HTTPS
  * Note that you'll need to plug the vpc subnet ID and backend_vip ipaddress into your config.json
* SCARY WARNING: The current EC2 configuration uses ephemeral disks which ARE LOST WHEN YOU SHUT DOWN THE NODE

#### config.json.ec2.example - Amazon EC2 Provisioning
```
{
  "provider": "ec2",
  "ec2_options": {
    "region": "us-east-1",
    "vpc_subnet": "subnet-c13410e9",
    "ami_id": "ami-e7e7fc8e",
    "ssh_username": "root"
  },
  "default_package": "http://s3.amazonaws.com/opscode-private-chef/el/6/x86_64/private-chef-11.1.3-1.el6.x86_64.rpm?AWSAccessKeyId=getonefromsupport&Expires=thistoo&Signature=andthis",
  "layout": {
    "topology": "ha",
    "api_fqdn": "api.opscode.piab",
    "manage_fqdn": "manage.opscode.piab",
    "analytics_fqdn": "analytics.opscode.piab",
    "backend_vip": {
      "hostname": "backend.opscode.piab",
      "ipaddress": "33.33.33.20",
      "device": "eth0",
      "heartbeat_device": "eth0"
    },
    "backends": {
      "backend1": {
        "hostname": "backend1.opscode.piab",
        "instance_type": "c3.xlarge",
        "ebs_optimized": true,
        "bootstrap": true
      },
      "backend2": {
        "hostname": "backend2.opscode.piab",
        "ebs_optimized": true,
        "instance_type": "c3.xlarge"
      }
    },
    "frontends": {
      "frontend1": {
        "hostname": "frontend1.opscode.piab",
        "ebs_optimized": false,
        "instance_type": "m3.medium"
      }
    }
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
Authors:
* Irving Popovetsky @irvingpop
* Jeremiah Snapp @jeremiahsnapp
* Patrick Wright @patrick-wright
