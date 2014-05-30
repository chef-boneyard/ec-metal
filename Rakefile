require 'json'
require 'fileutils'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# Environment variables to be consumed by ec-harness and friends
harness_dir = ENV['HARNESS_DIR'] = File.dirname(__FILE__)

# just in cases user has a different default Vagrant provider
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

def get_config
  JSON.parse(File.read('config.json'))
end

desc 'Install required Gems into the vendor/bundle directory'
task :bundle do
  system('bundle install --path vendor/bundle --binstubs')
end

desc 'Bring the VMs online and install+configure Enterprise Chef HA'
task :up => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  create_users_directory
  if system("#{harness_dir}/bin/chef-client -z -o ec-harness::private_chef_ha")
    Rake::Task['add_hosts'].execute
  end
end
task :start => :up

desc 'Bring the VMs online and then UPGRADE TORTURE'
task :upgrade_torture => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  create_users_directory
  if system("#{harness_dir}/bin/chef-client -z -o ec-harness::upgrade_torture")
    Rake::Task['add_hosts'].execute
  end
end

desc 'Simple upgrade step, installs the package from default_package. Machines must be running'
task :upgrade => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  create_users_directory
  if system("#{harness_dir}/bin/chef-client -z -o ec-harness::upgrade")
    Rake::Task['add_hosts'].execute
  end
end

desc 'Destroy all VMs'
task :destroy do
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::cleanup")
  Rake::Task['remove_hosts'].execute
end
task :cleanup => :destroy

desc 'SSH to a machine like so: rake ssh[backend1]'
task :ssh, [:machine] do |t,arg|
  Dir.chdir(File.join(harness_dir, 'vagrant_vms')) {
    system("vagrant ssh #{arg.machine}")
  }
end

# Vagrant standard but useful commands
%w(status halt suspend resume).each do |command|
  desc "Equivalent to running: vagrant #{command}"
  task :"#{command}" do
    Dir.chdir(File.join(harness_dir, 'vagrant_vms')) {
      system("vagrant #{command}")
    }
  end
end

task :config_copy do
  config_file = File.join(harness_dir, 'config.json')
  config_ex_file = File.join(harness_dir, 'examples', 'config.json.example')
  unless File.exists?(config_file)
    FileUtils.cp(config_ex_file, config_file)
  end
end

task :keygen do
  keydir = File.join(harness_dir, 'keys')
  Dir.mkdir keydir unless Dir.exists? keydir
  if Dir["#{keydir}/*"].empty?
    system("ssh-keygen -t rsa -P '' -q -f #{keydir}/id_rsa")
  end
end

desc 'Add hosts entries to /etc/hosts'
task :add_hosts do
  config = get_config
  config = fog_populate_ips(config) if config['provider'] == 'ec2'
  create_hosts_entries(config['layout'])
  print_final_message(config, harness_dir)
end

desc 'Remove hosts entries to /etc/hosts'
task :remove_hosts do
  config = get_config
  config = fog_populate_ips(config) if config['provider'] == 'ec2'
  remove_hosts_entries(config['layout'])
end

task :cachedir do
  if ENV['CACHE_PATH'] && Dir.exists?(ENV['CACHE_PATH'])
    cachedir = ENV['CACHE_PATH']
  else
    cachedir = File.join(harness_dir, 'cache')
    Dir.mkdir cachedir unless Dir.exists?(cachedir)
  end
  puts "Using package cache directory #{cachedir}"
end

task :berks_install do
  cookbooks_path = File.join(harness_dir, 'vendor/cookbooks')
  system("#{harness_dir}/bin/berks vendor #{cookbooks_path}")
end
