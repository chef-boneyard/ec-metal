#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

###
# High level options
###

default['private-chef']['installer_file'] = nil
default['private-chef']['analytics_installer_file'] = nil
default['private-chef']['reporting_installer_file'] = nil
default['private-chef']['manage_installer_file'] = nil

default['private-chef']['topology'] = "standalone"
default['private-chef']['api_fqdn'] = "api.mycompany.com"
default['private-chef']['manage_fqdn'] = "manage.mycompany.com"

###
# Underlying Configuration for /etc/opscode/chef-server.rb
###
default['private-chef']['configuration'] = {}
