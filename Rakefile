require 'json'
require 'fileutils'
require './cookbooks/ec-common/libraries/topo_helper.rb'
require './lib/ec-metal/config'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# Environment variables to be consumed by ec-harness and friends
ECMetal::Config.from_env
harness_dir = ECMetal::Config.harness_dir
repo_dir = ECMetal::Config.repo_path
harness_data_bag_dir = File.join(ECMetal::Config.repo_path, 'data_bags', 'harness')

# just in cases user has a different default Vagrant provider
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

def get_config
  JSON.parse(File.read(ECMetal::Config.test_config))
end

desc 'Install required Gems into the vendor/bundle directory'
task :bundle do
  sh('bundle install --path vendor/bundle --binstubs')
end

desc 'Bring the VMs online and install+configure Enterprise Chef HA'
task :up => :setup do
  create_users_directory
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::private_chef_ha")
end
task :start => :up

desc 'Bring the VMs online and then UPGRADE TORTURE'
task :upgrade_torture => :setup do
  create_users_directory
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::upgrade_torture")
end

desc 'Simple upgrade step, installs the package from default_package. Machines must be running'
task :upgrade => :setup do
  create_users_directory
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::upgrade")
end

desc "Copies pivotal.pem from chef server and generates knife.rb in the repo dir"
task :pivotal => :setup do
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::pivotal")
end

task :setup => [:print_environment, :keygen, :cachedir, :config_copy, :config_data_bag, :bundle, :berks_install]

desc 'Destroy all VMs'
task :destroy => :config_data_bag do
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::cleanup")
end
task :cleanup => :destroy

desc 'SSH to a machine like so: rake ssh[backend1]'
task :ssh, [:machine] do |t,arg|
  Dir.chdir(File.join(harness_dir, 'vagrant_vms')) {
    sh("vagrant ssh #{arg.machine}")
  }
end

desc "Print all ec-metal enviornment variables"
task :print_environment do
  puts "================== ec-metal ENV ==========================="
  ENV.each { |k,v| puts "#{k} = #{v}" if k.include?("ECM_") }
  puts "================== Config ================================="
  ECMetal::Config.to_hash.each { |k,v| puts "#{k} = #{v}" }
  puts "==========================================================="
end

# Vagrant standard but useful commands
%w(status halt suspend resume).each do |command|
  desc "Equivalent to running: vagrant #{command}"
  task :"#{command}" do
    Dir.chdir(File.join(harness_dir, 'vagrant_vms')) {
      sh("vagrant #{command}")
    }
  end
end

task :config_copy do
  unless ECMetal::Config.config_file && File.exists?(ECMetal::Config.config_file)
    config_file = File.join(harness_dir, 'config.json')
    config_ex_file = File.join(harness_dir, 'examples', 'config.json.example')
    unless File.exists?(config_file)
      FileUtils.cp(config_ex_file, config_file)
    end
  end
end

task :keygen => :data_bag_dir do
  keydir = ECMetal::Config.keys_dir
  key_data_bag_item = File.join(repo_dir, 'data_bags', 'harness', 'root_ssh.json')
  FileUtils.mkdir_p keydir

  if Dir["#{keydir}/*"].empty?
    if ECMetal::Config.keypair_path
      keypair_path = ECMetal::Config.keypair_path
      FileUtils.copy("#{keypair_path}/id_rsa", "#{keydir}/id_rsa")
      FileUtils.copy("#{keydir}/id_rsa", "#{keydir}/#{ECMetal::Config.keypair_name}") if ECMetal::Config.keypair_name
      FileUtils.copy("#{keypair_path}/id_rsa.pub", "#{keydir}/id_rsa.pub")
    else
      comment = ECMetal::Config.keypair_name.nil? ? "" : "-C #{ECMetal::Config.keypair_name}"
      command = "ssh-keygen #{comment} -P '' -q -f #{keydir}/id_rsa"
      puts "Keygen: #{command}"
      sh(command)
    end
  end

  puts "Adding keys to #{key_data_bag_item}"
  key_data = {
    'privkey' => File.read(File.join(keydir, 'id_rsa')),
    'pubkey'  => File.read(File.join(keydir, 'id_rsa.pub'))
  }
  File.write(key_data_bag_item, JSON.pretty_generate(key_data))
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
  cache_dir = ECMetal::Config.host_cache_dir
  FileUtils.mkdir_p cache_dir unless Dir.exists? cache_dir
  puts "Using package cache directory #{cache_dir}"
end

task :berks_install do
  cookbooks_path = File.join(repo_dir, 'vendor/cookbooks')
  sh("rm -r #{cookbooks_path}") if Dir.exists?(cookbooks_path)
  sh("#{harness_dir}/bin/berks vendor #{cookbooks_path}")
end

desc "Execute a command on a remote machine"
task :execute, [:machine, :command] do |t,arg|
  sh %Q{ssh -o StrictHostKeyChecking=no -i #{File.join(harness_dir, 'keys')}/id_rsa \
        #{ssh_user()}@#{machine(arg.machine)['hostname']} #{arg.command} }
end

desc "Copy a file/directory from local to the machine indicated"
task :scp, [:machine, :source_path, :remote_path] do |t,arg|
  sh %Q{scp -r -o StrictHostKeyChecking=no -i #{File.join(harness_dir, 'keys')}/id_rsa \
        #{arg.source_path} #{ssh_user()}@#{machine(arg.machine)['hostname']}:#{arg.remote_path} }
end

def machine(machine_name)
  topo = TopoHelper.new(:ec_config => get_config['layout'])
  merged_topo = topo.merged_topology
  machine = merged_topo[machine_name]
  abort("Machine #{machine_name} not found") if machine.nil?
  return machine
end

def ssh_user()
  config = get_config()
  case config['provider']
    when 'ec2'
      config['ec2_options']['ssh_username'] || 'ec2-user'
    when 'vagrant'
      'vagrant'
    else
      'root'
  end
end

task :data_bag_dir do
  puts "Creating data_bag_dir #{harness_data_bag_dir}"
  FileUtils.mkdir_p harness_data_bag_dir
end

task :config_data_bag => :data_bag_dir do
  config_file = ECMetal::Config.config_file
  data_bag_item = File.join(harness_data_bag_dir, 'config.json')
  puts "Generating config data bag item #{data_bag_item}"
  ECMetal::Config.write_data_bag_item(data_bag_item)
  sh("cp #{config_file} #{data_bag_item}")
end

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

