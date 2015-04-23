current_dir = ::File.dirname(__FILE__)
harness_dir = ENV['HARNESS_DIR'] || ::File.join(current_dir, '..')
repo = ENV['ECM_CHEF_REPO'] || ::File.join(current_dir, '..', 'chef-repo')
local_cookbooks = File.join(Pathname.new(File.dirname(__FILE__)).parent.to_s, 'cookbooks')
ENV['LOCAL_COOKBOOKS'] = local_cookbooks
FileUtils.mkdir_p(repo)
chef_repo_path repo
keys_dir = ::File.join(repo, 'keys')
keypair_name = ENV['ECM_KEYPAIR_NAME']
FileUtils.mkdir_p(keys_dir)
log_level                :info
log_location             STDOUT
node_name                'metal-provisioner'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            [::File.join(harness_dir, 'cookbooks'),
                         File.join(repo, 'cookbooks'),
                         ]
private_key_paths	 [keys_dir]

private_keys   keypair_name => ::File.join(keys_dir, 'id_rsa')
public_keys    keypair_name => ::File.join(keys_dir, 'id_rsa.pub')

chef_zero		 :port => 9010.upto(9999)
lockfile                 ::File.join(harness_dir, 'chef-client-running.pid')

# because SSL is hard
verify_api_cert         false
ssl_verify_mode         :verify_none
