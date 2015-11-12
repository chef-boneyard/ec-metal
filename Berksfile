source "https://api.berkshelf.com"

cookbook 'apt', '~> 2.0'
cookbook 'aws', '~> 2.0'
cookbook 'hostsfile', '~> 2.0'
cookbook 'lvm', git: 'https://github.com/chef-cookbooks/lvm', branch: 'irving/vgcreate_force'
cookbook 'yum', '~> 3.0'
cookbook 'yum-elrepo', :git => 'https://github.com/irvingpop/yum-elrepo', :branch => 'add_elrepo_testing_extras'
cookbook 'yum-epel'

# For loadtester hosts/guests
cookbook 'docker', :git => "https://github.com/irvingpop/chef-docker.git", :branch => "ubuntu_vivid"
cookbook 'chef-client'

cookbook 'push-jobs', :git => "https://github.com/manderson26/push-jobs", :branch => "ma/fix_containers"

cookbook 'ec-tools', :git => 'https://github.com/irvingpop/ec-tools'
