require_relative '../../cookbooks/ec-common/libraries/topo_helper'
require_relative '../../cookbooks/ec-common/libraries/fog_helper'
require 'resolv'

def fog
  FogHelper.new(region: CONFIG['ec2_options']['region'])
end

# cargo culted from: http://t-a-w.blogspot.com/2010/05/very-simple-parallelization-with-ruby.html
def Exception.ignoring_exceptions
  begin
    yield
  rescue Exception => e
    STDERR.puts e.message
  end
end

require 'thread'
module Enumerable
  def in_parallel_n(n)
    todo = Queue.new
    ts = (1..n).map{
      Thread.new{
        while x = todo.deq
          Exception.ignoring_exceptions{ yield(x[0]) }
        end
      }
    }
    each{|x| todo << [x]}
    n.times{ todo << nil }
    ts.each{|t| t.join}
  end
end

def resolve_bootstrap_host_name
  topo = TopoHelper.new(ec_config: CONFIG['layout'])
  ::Resolv.getaddress(topo.bootstrap_host_name)
rescue Resolv::ResolvError
  'notcreatedyet'
end

def elb_name
  resolve_bootstrap_host_name.gsub(/[.]/, '-')
end

harness_dir = ENV['HARNESS_DIR'] = EcMetal::Api.harness_dir
repo_dir = ENV['ECM_CHEF_REPO'] = EcMetal::Api.repo_dir

CONFIG = get_config

PRIVATE_KEY_PATH = ::File.join(repo_dir, 'keys', 'id_rsa')
USERS_PATH = ::File.join(harness_dir, 'users')
# chef_org = 'ponyville'
# chef_org_validation_pem = ::File.join(users_path, "#{chef_org}-validator.pem")
CHEF_USER = 'pinkiepie'
CHEF_USER_PEM = ::File.join(USERS_PATH, CHEF_USER, '.chef', "#{CHEF_USER}.pem")
if CONFIG['ec2_options'] && CONFIG['ec2_options']['elb'] && CONFIG['ec2_options']['elb'] == true
  CHEF_SERVER =  fog.get_elb_dns_name(elb_name)
else
  CHEF_SERVER = resolve_bootstrap_host_name
end
# chef_server_url = "https://#{chef_server}/organizations/#{chef_org}"
HARNESS_KNIFE_CONFIG = ::File.join(harness_dir, '.chef', 'knife.rb')
BERKS_CONFIG_DIR = ::File.join(harness_dir, 'berks_configs')


num_orgs = 900
parallel_uploaders = 10

def chef_server_url(orgname)
  "https://#{CHEF_SERVER}/organizations/#{orgname}"
end

def berks_config_json(orgname)
  {
    chef: {
      chef_server_url: chef_server_url(orgname),
      node_name: CHEF_USER,
      client_key: CHEF_USER_PEM
    },
    ssl: {
      verify: false
    }
  }
end

task :berks_prep do
  Dir.mkdir(BERKS_CONFIG_DIR) unless Dir.exists?(BERKS_CONFIG_DIR)
  berks_config_file = ::File.join(repo_dir, 'berks_config.json')
  File.open(berks_config_file, 'w') { |file| file.write(JSON.dump(berks_config_json('ponyville')))}
  sh "berks install -c #{berks_config_file} -q"
end

task :multiorg_prep => [:berks_prep] do
  sh "rsync -az --delete -e 'ssh -i #{PRIVATE_KEY_PATH}' root@#{resolve_bootstrap_host_name}:/srv/piab/users/ #{USERS_PATH}"
  (1..num_orgs).each do |orgnum|
    orgname = "org#{orgnum}"
    puts "Prepping org #{orgname}"
    berks_config_file = ::File.join(BERKS_CONFIG_DIR, "#{orgname}.json")
    File.open(berks_config_file, 'w') { |file| file.write(JSON.dump(berks_config_json(orgname)))}
    # sh "#{BERKS_BIN} install -c #{berks_config_file} -q"
  end
end

task :multiorg_uploader => [:multiorg_prep] do
  (1..num_orgs).in_parallel_n(parallel_uploaders) do |orgnum|
    start_time = Time.now
    orgname = "org#{orgnum}"
    puts "Uploading STARTING to org #{orgname} at #{start_time.to_s}"
    berks_config_file = ::File.join(BERKS_CONFIG_DIR, "#{orgname}.json")
    sh "knife upload /cookbooks -s #{chef_server_url(orgname)} -k #{CHEF_USER_PEM} -u #{CHEF_USER} -c #{HARNESS_KNIFE_CONFIG}"
    sh "berks upload -c #{berks_config_file}"
    end_time = Time.now
    duration_secs = end_time.to_i - start_time.to_i
    puts "Uploading COMPLETE to org #{orgname} at #{end_time}"
    puts "STATS #{orgname} #{duration_secs}"
  end
end
