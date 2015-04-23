require 'json'
require 'fileutils'
require './cookbooks/ec-common/libraries/topo_helper.rb'

require_relative 'lib/api.rb'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# just in cases user has a different default Vagrant provider
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

def get_config
  EcMetal::Api.config
end

# run chef-client commands not part of the api
def shellout_chef_client(run_list)
  sh("chef-client -z -o #{run_list} --force-formatter")
end

# desc 'Install required Gems into the vendor/bundle directory'
# task :bundle do
#   EcMetal::Api.bundle
# end

desc 'Bring the VMs online and install/configure Enterprise Chef. Optionally: "rake up debug" for verbose output'
task :up => :setup do
  log_level = ARGV.select {|i| i =~ /debug|info|warn|error|fatal/}.last
  EcMetal::Api.up(log_level)
  Rake::Task['add_hosts'].reenable
  Rake::Task['add_hosts'].invoke
end
task :start => :up

desc 'Run pedant tests on all machines'
task :pedant => :setup do
  shellout_chef_client('ec-harness::pedant')
end
task :verify => :pedant

desc 'Simple upgrade step, installs the package from default_package. Machines must be running'
task :upgrade => :setup do
  EcMetal::Api.create_users_directory
  shellout_chef_client('ec-harness::upgrade')
end

desc "Copies pivotal.pem from chef server and generates knife.rb in the repo dir"
task :pivotal => :setup do
  shellout_chef_client('ec-harness::pivotal')
end

desc 'Destroy all VMs'
task :destroy do
  EcMetal::Api.destroy
  Rake::Task['remove_hosts'].reenable
  Rake::Task['remove_hosts'].invoke
end
task :cleanup => :destroy

desc 'SSH to a machine like so: rake ssh[backend1]'
task :ssh, [:machine] do |t,arg|
  Dir.chdir(File.join(EcMetal::Api.harness_dir, 'vagrant_vms')) {
    sh("vagrant ssh #{arg.machine}")
  }
end

desc "Print all ec-metal enviornment variables"
task :print_enviornment do
  EcMetal::Api.print_enviornment
end

# Vagrant standard but useful commands
%w(status halt suspend resume).each do |command|
  desc "Equivalent to running: vagrant #{command}"
  task :"#{command}" do
    Dir.chdir(File.join(EcMetal::Api.harness_dir, 'vagrant_vms')) {
      sh("vagrant #{command}")
    }
  end
end

task :setup do
  EcMetal::Api.setup
end

desc 'Add hosts entries to /etc/hosts'
task :add_hosts do
  config = get_config
  config = fog_populate_ips(config) if config['provider'] == 'ec2'
  create_hosts_entries(config['layout'])
  print_final_message(config, EcMetal::Api.repo_dir)
end

desc 'Remove hosts entries to /etc/hosts'
task :remove_hosts do
  config = get_config
  config = fog_populate_ips(config) if config['provider'] == 'ec2'
  remove_hosts_entries(config['layout'])
end

task :cachedir do
  EcMetal::Api.cachedir
end

task :berks_install do
  EcMetal::Api.berks_install
end

task :berks_update do
  EcMetal::Api.berks_update
end

desc "Open csshx to the nodes of the server."
task :csshx do
  config = get_config
  config = fog_populate_ips(config) if config['provider'] == 'ec2'
  csshx(config, repo_dir)
end

desc "Execute a command on a remote machine"
task :execute, [:machine, :command] do |t,arg|
  sh %Q{ssh -o StrictHostKeyChecking=no -i #{File.join(EcMetal::Api.harness_dir, 'keys')}/id_rsa \
        #{ssh_user()}@#{machine(arg.machine)['hostname']} #{arg.command} }
end

desc "Copy a file/directory from local to the machine indicated"
task :scp, [:machine, :source_path, :remote_path] do |t,arg|
  sh %Q{scp -r -o StrictHostKeyChecking=no -i #{File.join(EcMetal::Api.harness_dir, 'keys')}/id_rsa \
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
