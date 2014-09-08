require 'json'
require 'fileutils'
require './cookbooks/ec-common/libraries/topo_helper.rb'
require_relative 'lib/api.rb'
Dir["lib/tasks/*.rake"].each { |t| load t }

task :default => [:up]

# just in cases user has a different default Vagrant provider
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

def get_config
  JSON.parse(File.read(ENV['ECM_CONFIG'] || 'config.json'))
end

desc 'Install required Gems into the vendor/bundle directory'
task :bundle do
  EcMetal::Api.bundle
end

desc 'Bring the VMs online and install+configure Enterprise Chef HA'
task :up => [:print_environment, :keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  EcMetal::Api.up
end
task :start => :up

desc 'Bring the VMs online and then UPGRADE TORTURE'
task :upgrade_torture => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  EcMetal::Api.create_users_directory
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::upgrade_torture")
end

desc 'Simple upgrade step, installs the package from default_package. Machines must be running'
task :upgrade => [:print_environment, :keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  EcMetal::Api.create_users_directory
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::upgrade")
end

desc "Copies pivotal.pem from chef server and generates knife.rb in the repo dir"
task :pivotal => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::pivotal")
end

desc 'Destroy all VMs'
task :destroy do
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::cleanup")
end
task :cleanup => :destroy

desc 'SSH to a machine like so: rake ssh[backend1]'
task :ssh, [:machine] do |t,arg|
  Dir.chdir(File.join(EcMetal::Api.harness_dir, 'vagrant_vms')) {
    sh("vagrant ssh #{arg.machine}")
  }
end

desc "Print all ec-metal environment variables"
task :print_environment do
  EcMetal::Api.print_environment
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

task :config_copy do
  EcMetal::Api.config_copy
end

task :keygen do
  EcMetal::Api.keygen
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

