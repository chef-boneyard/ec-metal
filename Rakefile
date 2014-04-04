require 'json'
require 'fileutils'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# Environment variables to be consumed by ec-harness and friends
ENV['HARNESS_DIR'] = File.dirname(__FILE__)

# Simple package version passing, TODO make this *much* smarter
ENV['OPC_INSTALL_PKG'] = 'private-chef-11.1.2-1.el6.x86_64.rpm' unless
  ENV['OPC_INSTALL_PKG'].is_a?(String) &&
  ENV['OPC_INSTALL_PKG'].length > 5

def get_config
  JSON.parse(File.read('config.json'))
end

def print_final_message(private_chef_config)
  backend1 = backend2 = nil
  private_chef_config['backends'].each do |node,attrs|
    if attrs['bootstrap'] == true
      backend1 = node
    else
      backend2 = node
    end
  end
  frontend1 = private_chef_config['frontends'].keys.first

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
  Backend Server 1.....#{private_chef_config['backends'][backend1]['hostname']}  (bootstrap)
  Backend Server 2.....#{private_chef_config['backends'][backend2]['hostname']}
  Backend VIP..........#{private_chef_config['backend_vip']['hostname']}
  Frontend Server 1....#{private_chef_config['frontends'][frontend1]['hostname']}

EOH
  puts final_message
end

desc 'Bring the VMs online and install+configure Enterprise Chef HA'
task :up => [:keygen, :cachedir, :berks_install, :config_copy] do
  create_users_directory
  if system('chef-client -z -o ec-harness::private_chef_ha')
    create_hosts_entries(get_config['layout'])
    print_final_message(get_config['layout'])
  end
end
task :start => :up

desc 'Destroy all VMs'
task :destroy do
  system('chef-client -z -o ec-harness::cleanup')
  remove_hosts_entries(get_config['layout'])
end
task :cleanup => :destroy

desc 'SSH to a machine like so: rake ssh[backend1]'
task :ssh, [:machine] do |t,arg|
  Dir.chdir(File.join(File.dirname(__FILE__), 'vagrant_vms')) {
    system("vagrant ssh #{arg.machine}")
  }
end

# Vagrant standard but useful commands
%w(status halt suspend resume).each do |command|
  desc "Equivalent to running: vagrant #{command}"
  task :"#{command}" do
    Dir.chdir(File.join(File.dirname(__FILE__), 'vagrant_vms')) {
      system("vagrant #{command}")
    }
  end
end

task :config_copy do
  config_file = File.join(File.dirname(__FILE__), 'config.json')
  config_ex_file = File.join(File.dirname(__FILE__), 'config.json.example')
  unless File.exists?(config_file)
    FileUtils.cp(config_ex_file, config_file)
  end
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
