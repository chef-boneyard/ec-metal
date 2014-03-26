task :default => [:up]

# Environment variables to be consumed by ec-harness and friends
ENV['HARNESS_DIR'] = File.dirname(__FILE__)

task :up do
  system('chef-client -z -o ec-harness::default')
end

task :destroy do
  system('chef-client -z -o ec-harness::cleanup')
end

task :status do
  Dir.chdir('vagrant_vms') {
    system('vagrant status')
  }
end

task :ssh, [:machine] do |t,arg|
  Dir.chdir('vagrant_vms') {
    system("vagrant ssh #{arg.machine}")
  }
end

task :keypair do
  keydir = 'keys'
  Dir.mkdir keydir unless Dir.exists? keydir
  system("ssh-keygen -t rsa -P '' -q -f #{File.dirname(__FILE__)}/#{keydir}/id_rsa")
end
