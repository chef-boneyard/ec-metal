# Load harness attributes from the config file
config_json = JSON.parse(File.read(File.join(ENV['HARNESS_DIR'], 'config.json')))
default['harness']['vagrant'] = config_json['vagrant_options']
default['harness']['vm_config'] = config_json['layout']

# HARNESS_DIR is set by the Rakefile to the project root directory
default['harness']['repo_path'] = ENV['HARNESS_DIR']
default['harness']['vms_dir'] = File.join(ENV['HARNESS_DIR'], 'vagrant_vms')

# host_cache_path is mapped to /tmp/cache on the VMs
default['harness']['host_cache_path'] = ENV['CACHE_PATH'] || File.join(ENV['HARNESS_DIR'], 'cache')

# SSH key distribution for inter-machine trust
default['harness']['root_ssh']['privkey'] = File.read(File.join(ENV['HARNESS_DIR'], 'keys', 'id_rsa'))
default['harness']['root_ssh']['pubkey'] = File.read(File.join(ENV['HARNESS_DIR'], 'keys', 'id_rsa.pub'))
