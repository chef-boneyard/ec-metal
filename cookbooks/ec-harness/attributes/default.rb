# Load harness attributes from the config file
harness_dir = ENV['HARNESS_DIR']
config_json = JSON.parse(File.read(File.join(harness_dir, ENV['ECM_CONFIG'] || 'config.json')))
default['harness']['harness_dir'] = harness_dir
default['harness']['provider'] = config_json['provider']
default['harness']['vagrant'] = config_json['vagrant_options']
default['harness']['ec2'] = config_json['ec2_options']
default['harness']['vm_config'] = config_json['layout']
default['harness']['default_package'] = ENV['DEFAULT_PACKAGE'] || config_json['default_package']
default['harness']['run_pedant'] = config_json['run_pedant'] || false
default['harness']['osc_install'] = config_json['osc_install'] || false
default['harness']['osc_upgrade'] = config_json['osc_upgrade'] || false
default['harness']['packages'] = config_json['packages']

# Provide an option to not monkeypatch the bugfixes
default['harness']['apply_ec_bugfixes'] = config_json['apply_ec_bugfixes']

# Provide an option to intentionally bomb out before running the upgrade reconfigure, so it can be done manually
default['harness']['vm_config']['lemme_doit'] = config_json['lemme_doit'] || false

# addon packages
default['harness']['manage_package'] = ENV['MANAGE_PACKAGE'] || config_json['manage_package']
default['harness']['reporting_package'] = ENV['REPORTING_PACKAGE'] || config_json['reporting_package']
default['harness']['pushy_package'] = ENV['PUSHY_PACKAGE'] || config_json['pushy_package']
default['harness']['analytics_package'] = ENV['ANALYTICS_PACKAGE'] || config_json['analytics_package']


# HARNESS_DIR is set by the Rakefile to the project root directory
repo_path = ENV['REPO_PATH']
default['harness']['repo_path'] = repo_path
default['harness']['vms_dir'] = File.join(harness_dir, 'vagrant_vms')

# host_cache_path is mapped to /tmp/cache on the VMs
default['harness']['host_cache_path'] = ENV['CACHE_PATH'] || File.join(harness_dir, 'cache')
default['harness']['vm_mountpoint'] = '/tmp/cache'

# SSH key distribution for inter-machine trust
default['harness']['root_ssh']['privkey'] = File.read(File.join(repo_path, 'keys', 'id_rsa'))
default['harness']['root_ssh']['pubkey'] = File.read(File.join(repo_path, 'keys', 'id_rsa.pub'))
