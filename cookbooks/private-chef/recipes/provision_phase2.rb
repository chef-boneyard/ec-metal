# encoding: utf-8
#
# Author:: Irving Popovetsky (<irving@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
#
# All Rights Reserved
#

execute "initial-p-c-c-reconfigure" do
  command "/opt/opscode/bin/private-chef-ctl reconfigure"
  action :run
end
