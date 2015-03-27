#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2012-2014 Opscode, Inc.
#
# All Rights Reserved
#

###
# High level options
###

default['private-chef']['installer_file'] = 'https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/trusty/chef-server-core_12.0.5-1_amd64.deb'
default['analytics']['analytics_installer_file'] = 'https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/trusty/opscode-analytics_1.1.1-1_amd64.deb'
default['private-chef']['reporting_installer_file'] = 'https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/trusty/opscode-reporting_1.2.3-1_amd64.deb'
default['private-chef']['manage_installer_file'] = 'https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/trusty/opscode-analytics_1.1.1-1_amd64.deb'
default['private-chef']['pushy_installer_file'] = 'https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/trusty/opscode-analytics_1.1.1-1_amd64.deb'

default['private-chef']['topology'] = "standalone"
default['private-chef']['api_fqdn'] = "api.mycompany.com"
default['private-chef']['manage_fqdn'] = "manage.mycompany.com"

default['root_ssh']['privkey'] = ''
default['root_ssh']['pubkey'] = ''

###
# Underlying Configuration for /etc/opscode/chef-server.rb
###
default['private-chef']['configuration'] = {}
default['private-chef']['manage_options'] = {}

# wrapping the aws cookbook
default['aws']['right_aws_version'] = '3.1.0'

# Organizations list
default['private-chef']['organizations'] = {
  'ponyville' => [
      'rainbowdash',
      'fluttershy',
      'applejack',
      'pinkiepie',
      'twilightsparkle',
      'rarity'
  ],
  'wonderbolts' => [
      'spitfire',
      'soarin',
      'rapidfire',
      'fleetfoot'
  ]
}
default['private-chef']['user_root'] = '/srv/piab/users'
default['private-chef']['users_sentinel_file'] = '/srv/piab/dev_users_created'
