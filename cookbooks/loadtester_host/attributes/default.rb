# encoding: utf-8

# hrm, something buggy with docker+btrfs on recent Ubuntu Trustys
default['loadtester_host']['use_btrfs'] = false

if node['loadtester_host']['use_btrfs'] == true
  default['docker']['options'] = '-s btrfs'
end