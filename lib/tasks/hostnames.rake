# host/unhost methods inspired by the Powder gem
# https://github.com/rodreegez/powder/blob/master/bin/powder#L197-224
def create_hosts_entries(env)
  puts 'Creating virtual host entries in your local /etc/hosts. (requires sudo)'
  vhost_entries = env['virtual_hosts'].map { |hostname, ip| "#{ip}\t#{hostname} #{hostname.split('.').first}\t#{marker(env)}" }
  hosts_file = File.read(hosts_file_path).split("\n").delete_if {|row| row =~ /.+(#{marker(env)})/}
  first_loopback_index = hosts_file.index {|i| i =~ /^(127.0.0.1).+/}
  hosts_file = hosts_file.insert(first_loopback_index + 1, vhost_entries)
  create_and_flush_hosts(hosts_file)
  puts "Environment virtual hosts entries added to /etc/hosts file, old host file is saved at #{ENV['HOME']}/hosts.bak"
end

def remove_hosts_entries(env)
  puts 'Restoring original /etc/hosts file. (requires sudo)'
  hosts_file = File.read(hosts_file_path).split("\n").delete_if {|row| row =~ /.+(#{marker(env)})/}
  create_and_flush_hosts(hosts_file)
  puts "Environment virtual hosts entries removed from /etc/hosts file, old host file is saved at #{ENV['HOME']}/hosts.bak"
end

def marker(env)
  "#ec-ha"
end

def hosts_file_path
  '/etc/hosts'
end

def create_and_flush_hosts(hosts_file)
  temp_hosts = "#{ENV['HOME']}/hosts-#{Time.now.to_i}"
  File.open(temp_hosts, 'w')  do
    |file| file.puts hosts_file.join("\n")
  end
  %x{cp #{hosts_file_path} #{ENV['HOME']}/hosts.bak}
  %x{sudo mv #{temp_hosts} #{hosts_file_path}}
  if RUBY_PLATFORM =~ /darwin/
    %x{dscacheutil -flushcache}
  end
end
