# encoding: utf-8

# we should probably add an "initialize" of some sort to api.rb to avoid this:
ENV['HARNESS_DIR'] = EcMetal::Api.harness_dir
ENV['ECM_CHEF_REPO'] = EcMetal::Api.repo_dir

desc 'Spin up load-testing machines'
task :loadtesters do
  # run twice because AWS
  sh('chef-client -z -o ec-harness::loadtesters')
end
task :setup_loadtest => :loadtesters

desc 'Run the load test'
task :run_loadtest do
  config = get_config
  num_loadtesters = config['loadtesters']['num_loadtesters']
  num_groups = config['loadtesters']['num_groups']
  num_containers = config['loadtesters']['num_containers']
  subwave_size = 8
  Dir.chdir(File.join(EcMetal::Api.harness_dir, 'users', 'pinkiepie')) {
    1.upto(num_containers/subwave_size).each do
    # Each subwave (100 nodes)
      (1..num_loadtesters).group_by { |i| i%num_groups }.each do |k,v|
      # each group
        search_req = ""
        v.map { |i| search_req += "name:*loadtester*-#{i} OR " }
        search_req.chomp!(' OR ')
        puts "Starting group at #{Time.now}: #{search_req}"
        sh("knife ssh '#{search_req}' -a cloud.public_ipv4 'for i in {1..#{subwave_size}}; do sudo docker run -d ponyville/ubuntu; sleep 0.1; done' -x ubuntu -i #{EcMetal::Api.repo_dir}/keys/id_rsa")
        puts "Finishing group at #{Time.now}: #{search_req}"
        puts "----------------------------------------------------------------\n\n\n\n"
      end
    end
  }
end

desc 'Destroy the load-testing machines'
task :cleanup_loadtest do
  sh('chef-client -z -o ec-harness::loadtesters_destroy')
end
task :destroy_loadtest => :cleanup_loadtest

task :pivotal => [:keygen, :cachedir, :config_copy, :berks_install] do
  sh('chef-client -z -o ec-harness::pivotal')
end

desc 'Spin up load-testing machines'
task :loadtest => [:berks_install] do
  sh('chef-client -z -o ec-harness::loadtesters')
end
