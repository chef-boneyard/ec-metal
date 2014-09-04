
# manage options
#default['harness']['manage_options'] = config_json['manage_options'] || {}

# TODO: May have to factor this out somehow
# Provide an option to intentionally bomb out before running the upgrade reconfigure, so it can be done manually
#default['harness']['vm_config']['lemme_doit'] = config_json['lemme_doit'] || false

# host_cache_path is mapped to /tmp/cache on the VMs
default['harness']['vm_mountpoint'] = '/tmp/ecm_cache'

# Initialize this attribute so that provisioner recipes can set this
default['harness']['provisioner_options'] = {}
