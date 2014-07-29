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
harness_dir = ENV['HARNESS_DIR']
repo = ENV['REPO_PATH']
FileUtils.mkdir_p(repo)
chef_repo_path repo
keys_dir = ::File.join(repo, 'keys')
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
private_keys		 "#{ENV['USER']}@#{::File.basename(harness_dir)}" => ::File.join(keys_dir, 'id_rsa')
public_keys		 "#{ENV['USER']}@#{::File.basename(harness_dir)}" => ::File.join(keys_dir, 'id_rsa.pub')
chef_zero		 :port => find_open_port
lockfile                 ::File.join(harness_dir, 'chef-client-running.pid')
