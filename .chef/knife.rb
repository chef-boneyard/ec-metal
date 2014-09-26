current_dir = ::File.dirname(__FILE__)
harness_dir = ENV['HARNESS_DIR']
repo = ENV['ECM_CHEF_REPO']
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
verify_api_cert          true
private_key_paths	 [keys_dir]

keypair_name ||= "#{ENV['USER']}@#{::File.basename(harness_dir)}"
private_keys   keypair_name => ::File.join(keys_dir, 'id_rsa')
public_keys    keypair_name => ::File.join(keys_dir, 'id_rsa.pub')

chef_zero		 :port => 9010.upto(9999)
lockfile                 ::File.join(harness_dir, 'chef-client-running.pid')
