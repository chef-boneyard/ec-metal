ec-metal
================
This tool uses chef-metal to provision, install and upgrade Enterprise Chef HA clusters.

## TOC
* [Goals](#goals)
* [Getting Started](#start)
* [Usage](#usage)
* [TODO](#todo)
* [Environments](#envs)
* [Running Vagrant](#vagrant)
  * [Using Vagrant](#vagrant_conf)
* [Running on AWS](#aws)
  * [Using ephemeral storage with DRBD](#aws-drbd)
  * [Using an EBS volume without DRBD](#aws-ebs)
* [Authors](#authors)

<a name="goals"/>
## Goals of this project
* Demonstrate the capabilities and (hopefully) best practices of chef-metal
* Enable Chef QA and Dev teams to test various EC topologies and packages in install and upgrade scenarios
* Enable Chef customers to deploy and upgrade Enterprise Chef without runbooks

<a name="start" />
## Getting Started
1. Select an [environment](#env)
1. Configure ec-metal according to the environment selected
1. Determine which [task](#tasks) you want to run
1. Set packages for installation or upgrade based on task
1. Run the ec-metal task!

<a name="usage" />
## Usage
ec-metal runs three main paths of execution:

 * `rake up` - this task will start up a non-existent environment or run Chef convergence on an existing envionment to the configured `default_package`.
 * `rake upgrade` - this task will use an existing environment and run Chef convergence to upgrade to the configured `default_package`.
 * `rake upgrade_torture` - this tasks uses the `packages` array.  This task will install the first version then upgrade each version in the array in order.

### Setting packages for installation and upgrades

| package key name | related chef package |
|----------|------------------|
| default_package | private-chef |
| manage_package | opscode-manage |
| reporting_package | opscode-reporting |
| pushy_package | opscode-push-jobs-server |
| packages | array of private-chef packages |

* When `manage_package`, `reporting_package`, or `pushy_package` are omitted from the config they will not be installed/upgraded.

**When in doubt reference the example config files!**

Notable tasks:
* `rake destroy` will tear down all instances
* `rake ssh[nodename]` will ssh into the designated instance
* `rake status` will display current topology status

<a name="todo"/>
## TODO
NOTE: This is still a WIP under heavy development
* Figure out a nice way to assist with EC package downloads and caching (dendrite?)
* Testing
* Ability to drive installation, upgrade and restore-from-backup on already-provisioned servers (ex: customer environments) possibly using: https://github.com/double-z/chef-metal-ssh
* EC2 improvements
  - Switch to using EC2 IAM roles to avoid slinging aws keys around.
    + Rake Tasks to auto-create IAM Roles
  - Rake Task to auto-create the VPC networking
  - Creation of ELB (load balancers) and auto-add frontends to the ELB
  - rake ssh to find and connect you to your AWS instances

<a name="envs"/>
## Environments
ec-metal supports:
* [vagrant / virtualbox](#vagrant)
* [aws / ec2](#aws)

Follow the instructions specific to the environment of your choosing.

<a name="vagrant" />
## Running Virtualbox with Vagrant
1. Install Vagrant and Virtualbox (tested on Vagrant 1.5 and 1.6)
1. Copy `config.json.example` to `config.json`
1. Edit Vagrant [config.json](#vagrant_conf)
  * **Note on memory:** HA topologies with DRBD can be demanding on your system. Usage has showed the backend systems require at least 2.5G RAM and the frontend requires at least 1G RAM to order to install and operate nominally.
1. Download the private-chef packages to the ec-metal/cache directory or point to your own installer cache with `$CACHE_PATH`
1. Run [rake tasks](#tasks)

<a name="vagrant_conf" />
### Vagrant Configuration Attributes
[Provided Template](config.json.example)

*Core attributes to configure*

| vagrant_options | description |
|-----------------|-------------|
| box | vagrant box name |
| box_url | vagrant box url |

The `layouts` object should not need to be changed in most cases.

<a name="aws" />
## Running ec2 on AWS
1. Create the .aws/config file as described here: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#d0e726
  
  ```
  [default]
  region = us-east-1
  aws_access_key_id = MYACCESSKEY
  aws_secret_access_key = MySecRetkEy
  ```
1. Copy `config.json.ec2.example` to `config.json`
1. Edit ec2 [config.json](#ec2_conf)
  * Obtain valid s3 download links for the packages you want to install
1. Find a CentOS 6.5 AMI: defaults to using a CentOS-6.5 + Heartbleed patches + Chef 11.12.4 built from https://github.com/irvingpop/packer-chef-amazon. Here is a list of known AMIs.

  | Region    | AMI ID       |
  | --------- | ------------ |
  | us-east-1 | ami-54ac4d3c |
  | us-west-1 | ami-c0152e85 |
  | us-west-2 | ami-937502a3 |

1. Create a VPC that has a "Public" Subnet with an Internet Gateway, and VPC security groups that allow inbound SSH and HTTPS

  ```
  # CREATING THE VPC USING THE CLI TOOLS
  aws ec2 create-vpc --cidr-block "33.33.0.0/16"
  # note your VpcId
  aws ec2 modify-vpc-attribute --vpc-id vpc-myvpcid --enable-dns-hostnames
  # now create a subnet
  aws ec2 create-subnet --vpc-id vpc-myvpcid --cidr-block "33.33.33.0/24"
  # note your SubnetId
  aws ec2 create-internet-gateway
  # note your InternetGatewayId
  aws ec2 attach-internet-gateway --internet-gateway-id igw-myigwid --vpc-id vpc-myvpcid
  # should be true
  aws ec2 describe-route-tables
  # note the RouteTableId assigned to your VpcId
  aws ec2 create-route --route-table-id rtb-myrtbid --destination "0.0.0.0/0" --gateway-id igw-myigwid

  # ADJUSTING THE SECURITY GROUPS to allow ssh, http, https
  # find the default security group for your VPC
  aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-b4c52dd1
  # note the GroupId
  aws ec2 authorize-security-group-ingress --group-id sg-mysgid --protocol tcp --port 22 --cidr "0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-id sg-mysgid --protocol tcp --port 80 --cidr "0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-id sg-mysgid --protocol tcp --port 443 --cidr "0.0.0.0/0"
  ```
1. Set the new vpc subnet ID and backend_vip ipaddress in your config.json.

*Core attributes to configure*

| key | description |
|-----|-------------|
| region | aws region name |
| vpc_subnet | aws subnet name |
| ami_id | aws image id | 
| backend_vip -> ipaddress | aws vpc ip |

**WARNING: The current EC2 configuration uses ephemeral disks which ARE LOST WHEN YOU SHUT DOWN THE NODE**

<a name="aws-drbd"/>
### ec2 DRBD Configuration Attributes
[Provided Template](config.json.ec2.example)

```json
{
  "provider": "ec2",
  "ec2_options": {
    "region": "us-east-1",
    "vpc_subnet": "subnet-c13410e9",
    "ami_id": "ami-e7e7fc8e",
    "ssh_username": "root",
    "use_private_ip_for_ssh": false
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

<a name="aws-ebs"/>
### ec2 EBS Configuration Attributes
* The single EBS volume is attached and mounted ONLY to the active backend node
* It is highly recommended to use EBS-optimized instances and PIOPS volumes
* Note the three added attributes to the ec2_options:
  - `backend_storage_type`: `ebs`
  - `ebs_disk_size`: `100`
  - `ebs_use_piops`: `true`
* The PIOPS value is automatically calculated as disk_size * 30 up to the maximum of 4000
* *Core attributes are the same as the DRBD config*

```json
{
  "provider": "ec2",
  "ec2_options": {
    "region": "us-west-2",
    "vpc_subnet": "subnet-8b0519ff",
    "ami_id": "ami-937502a3",
    "ssh_username": "root",
    "backend_storage_type": "ebs",
    "ebs_disk_size": "100",
    "ebs_use_piops": true,
    "use_private_ip_for_ssh": false
  }
...
```

<a name="bugfixes"/>
## Applying EC bug fixes
ec-metal will apply EC bugfixes by default (as shown in the https://github.com/opscode/ec-metal/blob/master/cookbooks/private-chef/recipes/bugfixes.rb recipe).  To disable this feature, set the following option in your config.json:
```json
{
  "apply_ec_bugfixes": false
}
```

<a name="topologies"/>
## Support Topologies
ec-metal currently supports the `ha` and `tier` topologies.  Please note that if you use the `tier` topology you must set the `backend_vip` `ipaddress` to be the same as the IP address of the bootstrap (and only) backend node like so:
```json
{
   "layout": {
    "topology": "tier",
    "backend_vip": {
      "ipaddress": "33.33.33.20"
    },
    "backends": {
      "backend1": {
        "ipaddress": "33.33.33.20",
        "bootstrap": true
      }
    }
  }
}
```

### Contributing
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

<a name="authors"/>
### License and Authors
Authors:
* Irving Popovetsky @irvingpop
* Jeremiah Snapp @jeremiahsnapp
* Patrick Wright @patrick-wright
