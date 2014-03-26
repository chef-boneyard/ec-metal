
default['harness']['repo_path'] = ENV['HARNESS_DIR']
default['harness']['vms_dir'] = File.join(ENV['HARNESS_DIR'], 'vagrant_vms')
default['harness']['host_cache_path'] = ENV['CACHE_PATH'] || '/oc/EC/Downloads'

default['harness']['vagrant']['box'] = 'opscode-centos-6.5'
default['harness']['vagrant']['box_url'] = 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.5_chef-provisionerless.box'

# Disk 2 size in GBs
default['harness']['vagrant']['disk2_size'] = 2

default['harness']['vm_config'] = JSON.parse(File.read(File.join(ENV['HARNESS_DIR'], 'config.json')))

# SSH key distribution for inter-machine trust
default['harness']['root_ssh']['privkey'] = File.read(File.join(ENV['HARNESS_DIR'], 'keys', 'id_rsa'))
default['harness']['root_ssh']['pubkey'] = File.read(File.join(ENV['HARNESS_DIR'], 'keys', 'id_rsa.pub'))
