current_dir = ::File.dirname(__FILE__)
harness_dir = ::File.expand_path(::File.join(current_dir, '..'))
keys_dir = ::File.join(harness_dir, 'keys')
log_level                :info
log_location             STDOUT
node_name                "metal-mastah"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            [::File.join(harness_dir, 'cookbooks')]
verify_api_cert          true
private_key_paths	 [keys_dir]
private_keys		 "#{ENV['USER']}@#{::File.basename(harness_dir)}" => ::File.join(keys_dir, 'id_rsa')
public_keys		 "#{ENV['USER']}@#{::File.basename(harness_dir)}" => ::File.join(keys_dir, 'id_rsa.pub')
