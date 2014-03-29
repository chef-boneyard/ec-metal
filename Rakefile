require 'json'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# Environment variables to be consumed by ec-harness and friends
ENV['HARNESS_DIR'] = File.dirname(__FILE__)

def get_config
  JSON.parse(File.read('config.json'))
end

def print_final_message(private_chef_config)
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

Web UI...............https://#{private_chef_config['manage_fqdn']}
API FQDN.............https://#{private_chef_config['api_fqdn']}
Servers:
  Backend Server 1.....#{private_chef_config['backends']['backend1']['hostname']}  (bootstrap)
  Backend Server 2.....#{private_chef_config['backends']['backend2']['hostname']}
  Backend VIP..........#{private_chef_config['backend_vip']['hostname']}
  Frontend Server 1....#{private_chef_config['frontends']['frontend1']['hostname']}

EOH
  puts final_message
end

desc 'Bring the VMs online and install+configure Enterprise Chef HA'
task :up => [:keygen, :cachedir, :berks_install] do
  system('chef-client -z -o ec-harness::default')
  create_hosts_entries(get_config)
  print_final_message(get_config)
end

desc 'Destroy all VMs'
task :destroy do
  system('chef-client -z -o ec-harness::cleanup')
  remove_hosts_entries(get_config)
end

desc 'Show the Vagrant/VM status'
task :status do
  Dir.chdir('vagrant_vms') {
    system('vagrant status')
  }
end

desc 'SSH to a machine like so: rake ssh[backend1]'
task :ssh, [:machine] do |t,arg|
  Dir.chdir('vagrant_vms') {
    system("vagrant ssh #{arg.machine}")
  }
end

desc 'Halt the environment'
task :halt do
  Dir.chdir('vagrant_vms') {
    system("vagrant halt")
  }
end

task :keygen do
  keydir = File.join(File.dirname(__FILE__), 'keys')
  Dir.mkdir keydir unless Dir.exists? keydir
  if Dir["#{keydir}/*"].empty?
    system("ssh-keygen -t rsa -P '' -q -f #{keydir}/id_rsa")
  end
end

task :cachedir do
  if ENV['CACHE_PATH'] && Dir.exists?(ENV['CACHE_PATH'])
    cachedir = ENV['CACHE_PATH']
  else
    cachedir = File.join(File.dirname(__FILE__), 'cache')
    Dir.mkdir cachedir unless Dir.exists?(cachedir)
  end
  puts "Using package cache directory #{cachedir}"
end

task :berks_install do
  cookbooks_path = File.join(File.dirname(__FILE__), 'vendor/cookbooks')
  system("berks install --path #{cookbooks_path}")
end
