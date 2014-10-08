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

desc 'Install required Gems into the vendor/bundle directory'
task :bundle do
  EcMetal::Api.bundle
end

desc 'Bring the VMs online and install/configure Enterprise Chef. Optionally: "rake up debug" and/or "rake up force_formatter" for verbose output'
task :up => :setup do
  log_level = ARGV.select {|i| i =~ /debug|info|warn|error|fatal/}.last
  force_formatter = ARGV.select {|i| i =~ /force(-|_)formatter/}.last
  EcMetal::Api.up(log_level, force_formatter)
end
task :start => :up

desc 'Bring the VMs online and then UPGRADE TORTURE'
task :upgrade_torture => :setup do
  EcMetal::Api.create_users_directory
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::upgrade_torture")
end

desc 'Simple upgrade step, installs the package from default_package. Machines must be running'
task :upgrade => :setup do
  EcMetal::Api.create_users_directory
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::upgrade")
end

desc "Copies pivotal.pem from chef server and generates knife.rb in the repo dir"
task :pivotal => :setup do
  sh("#{EcMetal::Api.harness_dir}/bin/chef-client -z -o ec-harness::pivotal")
end

desc 'Spin up load-testing machines'
task :loadtesters do
  # run twice because AWS
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::loadtesters")
end
task :setup_loadtest => :loadtesters

desc 'Run the load test'
task :run_loadtest do
  config = get_config
  num_loadtesters = config['loadtesters']['num_loadtesters']
  num_groups = config['loadtesters']['num_groups']
  num_containers = config['loadtesters']['num_containers']
  subwave_size = 8
  Dir.chdir(File.join(harness_dir, 'users', 'pinkiepie')) {
    1.upto(num_containers/subwave_size).each do
    # Each subwave (100 nodes)
      (1..num_loadtesters).group_by { |i| i%num_groups }.each do |k,v|
      # each group
        search_req = ""
        v.map { |i| search_req += "name:*loadtester-#{i} OR " }
        search_req.chomp!(' OR ')
        puts "Starting group at #{Time.now}: #{search_req}"
        system("#{harness_dir}/bin/knife ssh '#{search_req}' -a cloud.public_ipv4 'for i in {1..#{subwave_size}}; do sudo docker run -d ponyville/ubuntu; done' -x ubuntu -i #{repo_dir}/keys/id_rsa")
        puts "Finishing group at #{Time.now}: #{search_req}"
        puts "----------------------------------------------------------------\n\n\n\n"
      end
    end
  }
end

desc 'Destroy the load-testing machines'
task :cleanup_loadtest do
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::loadtesters_destroy")
end
task :destroy_loadtest => :cleanup_loadtest

task :pivotal => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::pivotal")
end

desc 'Spin up load-testing machines'
task :loadtest => [:berks_install] do
  system("#{harness_dir}/bin/chef-client -z -o ec-harness::loadtesters")
end

desc "Copies pivotal.pem from chef server and generates knife.rb in the repo dir"
task :pivotal => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::pivotal")
end

task :pivotal => [:keygen, :cachedir, :config_copy, :bundle, :berks_install] do
  sh("#{harness_dir}/bin/chef-client -z -o ec-harness::pivotal")
end

desc 'Destroy all VMs'
task :destroy do
  EcMetal::Api.destroy
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
#         sh(cmd)
#       end
#     end
#   end
# end

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
