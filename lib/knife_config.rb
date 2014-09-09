class KnifeConfig
  def self.write_knife_config(file, harness_dir, chef_repo, keys_dir, keypair_name, local_cookbooks)
    knife = knife_string(chef_repo, harness_dir, keys_dir, keypair_name, local_cookbooks)
    File.open(file, 'w') { |f| f.write knife } 
  end

  def self.knife_string(repo, harness_dir, keys_dir, keypair_name, local_cookbooks)
%Q{
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

chef_repo_path '#{repo}'
keys_dir = '#{::File.join(repo, 'keys')}'

#{"keypair_name = '#{keypair_name}'" unless keypair_name.nil?}
#{"keypair_name = '#{ENV['USER']}@#{::File.basename(harness_dir)}'" if keypair_name.nil?}

log_level                :info
log_location             STDOUT
node_name                'metal-provisioner'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            [
                          '#{local_cookbooks}',
                          '#{File.join(harness_dir, 'cookbooks')}',
                          '#{File.join(repo, 'cookbooks')}',
                          '#{File.join(repo, 'vendor', 'cookbooks')}'
                         ]
verify_api_cert          true
private_key_paths	 ['#{keys_dir}']

private_keys   keypair_name => '#{::File.join(keys_dir, 'id_rsa')}'
public_keys    keypair_name => '#{::File.join(keys_dir, 'id_rsa.pub')}'

chef_zero		 :port => find_open_port
lockfile                 '#{::File.join(harness_dir, 'chef-client-running.pid')}'
}
  end
end
