require './lib/ec-metal/config'
def find_open_port
  port = 8889
  begin
    s = TCPServer.new('127.0.0.1', port)
    s.close
  rescue
    port += 1
    retry
  end
  port
end

current_dir = ::File.dirname(__FILE__)
harness_dir = ECMetal::Config.harness_dir
repo = ECMetal::Config.repo_path

FileUtils.mkdir_p(repo)
chef_repo_path repo
keys_dir = ECMetal::Config.keys_dir
keypair_name = ECMetal::Config.keypair_name
FileUtils.mkdir_p(keys_dir)
log_level                :info
log_location             STDOUT
node_name                "metal-mastah"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            [::File.join(harness_dir, 'cookbooks'),
                         File.join(repo, 'cookbooks'),
                         ]
verify_api_cert          true
private_key_paths	 [keys_dir]

private_keys   keypair_name => ::File.join(keys_dir, 'id_rsa')
public_keys    keypair_name => ::File.join(keys_dir, 'id_rsa.pub')

chef_zero		 :port => find_open_port
lockfile                 ::File.join(harness_dir, 'chef-client-running.pid')
