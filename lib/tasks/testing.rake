
desc 'Run unit tests'
task :test do
  %w(ec-harness private-chef).each do |cookbook|
    puts "Running chefspec tests for cookbook: #{cookbook}"
    Dir.chdir(File.join(EcMetal::Api.harness_dir, 'cookbooks', cookbook)) {
      sh('rspec')
    }
  end
end
