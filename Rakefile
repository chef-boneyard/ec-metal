require 'json'
require 'fileutils'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# Environment variables to be consumed by ec-harness and friends
harness_dir = ENV['HARNESS_DIR'] ||= File.dirname(__FILE__)
repo_dir = ENV['REPO_PATH'] ||= File.join(harness_dir, 'chef-repo')

# just in cases user has a different default Vagrant provider
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

def get_config
  JSON.parse(File.read(ENV['ECM_CONFIG'] || 'config.json'))
end

desc 'Install required Gems into the vendor/bundle directory'
task :bundle do
  system('bundle install --path vendor/bundle --binstubs')
end

desc 'Bring the VMs online and install+configure Enterprise Chef HA'
task :up => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  create_users_directory
  if system("#{harness_dir}/bin/chef-client -z -o ec-harness::private_chef_ha")
    Rake::Task['add_hosts'].execute unless ENV['disable_hosts']
  end
end
task :start => :up

desc 'Bring the VMs online and then UPGRADE TORTURE'
task :upgrade_torture => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  create_users_directory
  if system("#{harness_dir}/bin/chef-client -z -o ec-harness::upgrade_torture")
    Rake::Task['add_hosts'].execute unless ENV['disable_hosts']
  end
end

desc 'Simple upgrade step, installs the package from default_package. Machines must be running'
task :upgrade => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  create_users_directory
  if system("#{harness_dir}/bin/chef-client -z -o ec-harness::upgrade")
    Rake::Task['add_hosts'].execute unless ENV['disable_hosts']
  end
end

desc 'Spin up load-testing machines'
task :loadtesters => [:berks_install] do
  # arg run this twice for ohai hints - WHY
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::loadtesters")
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::loadtesters")
end

desc 'Spin up load-testing machines'
task :run_loadtest do
  Dir.chdir(File.join(harness_dir, 'users', 'pinkiepie')) {
    system("#{harness_dir}/bin/knife ssh 'name:*loadtester*' -a cloud.public_ipv4 'for i in {1..2000}; do sudo docker run -d ponyville/ubuntu; done' -x ubuntu -i #{repo_dir}/keys/id_rsa")
  }
end

desc 'Destroy the load-testing machines'
task :cleanup_loadtest do
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::loadtesters_destroy")
end
task :destroy_loadtest => :cleanup_loadtest

desc 'Destroy all VMs'
task :destroy do
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::cleanup")
  Rake::Task['remove_hosts'].execute unless ENV['disable_hosts']
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
  keydir = File.join(repo_dir, 'keys')
  FileUtils.mkdir_p keydir
  if Dir["#{keydir}/*"].empty?
    system("ssh-keygen -t rsa -P '' -q -f #{keydir}/id_rsa")
  end
end

desc 'Add hosts entries to /etc/hosts'
task :add_hosts do
  config = get_config
  config = fog_populate_ips(config) if config['provider'] == 'ec2'
  create_hosts_entries(config['layout'])
  print_final_message(config, repo_dir)
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
    FileUtils.mkdir_p cachedir
  end
  puts "Using package cache directory #{cachedir}"
end

task :berks_install do
  cookbooks_path = File.join(ENV['REPO_PATH'], 'vendor/cookbooks')
  system("rm -r #{cookbooks_path}") if Dir.exists?(cookbooks_path)
  system("#{harness_dir}/bin/berks vendor #{cookbooks_path}")
end

# Fix to work with topohelper
# desc "Runs remote commands via ssh.  Usage remote[servername, 'command args string']"
# # "knife-opc user create rockawesome patrick wright patrick@getchef.com password"
# # "knife-opc org create myorg2 supercoolorg -a rockawesome"
# task :remote, [:machine, :command] do |t, arg|
#   configip = fog_populate_ips(get_config)
#   %w(backends frontends standalones).each do |whichend|
#     configip['layout'][whichend].each do |node,attrs|
#       if node == arg[:machine]
#         case configip['provider']
#           when 'ec2'
#             ssh_username = configip['ec2_options']['ssh_username'] || 'ec2-user'
#           when 'vagrant'
#             ssh_username = 'vagrant'
#           else
#             ssh_username = 'root'
#         end
#         cmd = "ssh #{ssh_username}@#{attrs['ipaddress']} -o StrictHostKeyChecking=no -i #{File.join(harness_dir, 'keys')}/id_rsa \"#{arg[:command]}\""
#         puts "Executing '#{arg[:command]}' on #{arg[:machine]}"
#         system(cmd)
#       end
#     end
#   end
# end

# task :ec2_to_file do
#   file = File.open('ec2_ips', 'w')
#   file.truncate(file.size)
#   configip = fog_populate_ips(get_config)
#   %w(backends frontends standalones).each do |whichend|
#     configip['layout'][whichend].each do |node,attrs|
#       file.write("#{node}=#{attrs['ipaddress']}\n")
#     end
#   end
# end

