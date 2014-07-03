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

def mydomainname(hostname)
    hostname.
    split('.')[1..-1].
    join('.')
end

def marker(env)
  "#ec-metal_#{mydomainname(env['api_fqdn'])}"
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

def print_cool_text
   final_message = <<-EOH

    _/_/_/              _/                          _/
   _/    _/  _/  _/_/      _/      _/    _/_/_/  _/_/_/_/    _/_/
  _/_/_/    _/_/      _/  _/      _/  _/    _/    _/      _/_/_/_/
 _/        _/        _/    _/  _/    _/    _/    _/      _/
_/        _/        _/      _/        _/_/_/      _/_/    _/_/_/

     _/_/_/  _/                      _/_/      _/    _/    _/_/
  _/        _/_/_/      _/_/      _/          _/    _/  _/    _/
 _/        _/    _/  _/_/_/_/  _/_/_/_/      _/_/_/_/  _/_/_/_/
_/        _/    _/  _/          _/          _/    _/  _/    _/
 _/_/_/  _/    _/    _/_/_/    _/          _/    _/  _/    _/

EOH
  puts final_message
end

def print_final_message(private_chef_config, harness_dir)
  print_cool_text
  puts "Web UI...............https://#{private_chef_config['layout']['manage_fqdn']}"
  puts "API FQDN.............https://#{private_chef_config['layout']['api_fqdn']}"
  puts "Analytics FQDN.......https://#{private_chef_config['layout']['analytics_fqdn']}\n\n"

  case private_chef_config['provider']
  when 'ec2'
    ssh_username = private_chef_config['ec2_options']['ssh_username'] || 'ec2-user'
  when 'vagrant'
    ssh_username = 'vagrant'
  else
    ssh_username = 'root'
  end
  keydir = File.join(harness_dir, 'keys')

  %w(backends frontends).each do |whichend|
    private_chef_config['layout'][whichend].each do |node,attrs|
      puts "Bootstrap node is: #{node}" if attrs['bootstrap'] == true
      puts "#{node}: https://#{attrs['hostname']} | ssh #{ssh_username}@#{attrs['ipaddress']} -i #{keydir}/id_rsa"
    end
  end
  puts ""
end
