# encoding: utf-8
require 'chef/server_api'
require 'inifile'

module EcHarness
  # Define our 3 reusable topology types and make them available in recipe DSL
  def ecm_topo
    @topo ||= TopoHelper.new(ec_config: node['harness']['vm_config'], exclude_layers: ['loadtesters'])
  end

  def ecm_topo_chef
    @topo_chef ||= TopoHelper.new(ec_config: node['harness']['vm_config'], include_layers: ec_layers)
  end

  def ecm_topo_analytics
    @topo_analytics ||= TopoHelper.new(ec_config: node['harness']['vm_config'],include_layers: analytics_layers)
  end

  def cloud_machine_created?(vmname)
    rest = Chef::ServerAPI.new()
    begin
      nodeinfo = rest.get("/nodes/#{vmname}")
    rescue Net::HTTPServerException
      # Handle the 404 meaning the machine hasn't been created yet
      nodeinfo = {'normal' => { 'chef_provisioning' => {} } }
    end
    driver_info = nodeinfo['normal']['chef_provisioning']['reference'] || {}
    return true if driver_info.has_key?('server_id')
    false
  end

  def machine_options_for_provider(vmname, config)
    case node['harness']['provider']
    when 'ec2'
      Ec2ConfigHelper.generate_config(vmname, config, node)
    when 'vagrant'
      VagrantConfigHelper.generate_config(vmname, config, node)
    else
      raise "No provider set!"
    end
  end

  def installer_path(ec_package)
    return nil unless ec_package
    return ec_package if ::URI.parse(ec_package).absolute?
    ::File.join(node['harness']['vm_mountpoint'], ec_package)
  end

  def search_bootstrap_node_ip
    search(:node, "name:#{topo.bootstrap_node_name}").map { |n| n.ipaddress }.first
  end

  def privatechef_attributes
    packages = package_attributes

    attributes = node['harness']['vm_config'].to_hash
    attributes['configuration'] = {} unless attributes['configuration']
    attributes['installer_file'] = packages['ec']
    unless packages['manage'] == nil
      attributes['manage_installer_file'] = packages['manage']
      attributes['configuration']['opscode_webui'] = { 'enable' => false }
      attributes['manage_options'] = node['harness']['manage_options']
    end
    attributes['reporting_installer_file'] = packages['reporting']
    attributes['pushy_installer_file'] = packages['pushy']
    unless packages['analytics'] == nil
      attributes['analytics_installer_file'] = packages['analytics']
      attributes['configuration']['dark_launch'] = { 'actions' => true }
      attributes['configuration']['rabbitmq'] = {}
      attributes['configuration']['rabbitmq']['node_ip_address'] = '0.0.0.0'
      if ecm_topo.is_ha?
        attributes['configuration']['rabbitmq']['vip'] = attributes['backend_vip']['ipaddress']
      else
        attributes['configuration']['rabbitmq']['vip'] = ecm_topo.bootstrap_host_name
      end
    end
    attributes
  end

  def analytics_attributes
    packages = package_attributes
    attributes = node['harness']['vm_config'].to_hash
    attributes['configuration'] ||= {}
    attributes['installer_file'] = packages['ec']
    unless packages['analytics'] == nil
      attributes['analytics_installer_file'] = packages['analytics']
    end
    attributes
  end

  def cloud_attributes(provider)
    cloud_attrs = node['harness'][provider].to_hash
    cloud_attrs['provider'] = provider

    case provider
    when 'ec2'
      aws_credentials = load_aws_credentials
      cloud_attrs['aws_access_key_id'] ||= aws_credentials['default'][:aws_access_key_id]
      cloud_attrs['aws_secret_access_key'] ||= aws_credentials['default'][:aws_secret_access_key]
    end

    cloud_attrs
  end

  def package_attributes
    packages = {}

    packages['ec'] = installer_path(node['harness']['default_package'])
    packages['manage'] = installer_path(node['harness']['manage_package'])
    packages['reporting'] = installer_path(node['harness']['reporting_package'])
    packages['pushy'] = installer_path(node['harness']['pushy_package'])
    packages['analytics'] = installer_path(node['harness']['analytics_package'])

    packages
  end

  def is_analytics?
   (node['harness']['vm_config']['analytics_backends'] ||
    node['harness']['vm_config']['analytics_frontends'] ||
    node['harness']['vm_config']['analytics_standalones'] ||
    node['harness']['vm_config']['analytics_workers'])
  end

  def analytics_layers
    ['analytics_backends',
     'analytics_frontends',
     'analytics_standalones',
     'analytics_workers']
  end

  def ec_layers
    %w(frontends backends standalones)
  end

  private

   def load_aws_ini(credentials_ini_file)
    inifile = IniFile.load(File.expand_path(credentials_ini_file))
    credentials = {}
    if inifile
      inifile.each_section do |section|
        if section =~ /^\s*profile\s+(.+)$/ || section =~ /^\s*(default)\s*/
          profile_name = $1.strip
          profile = inifile[section].inject({}) do |result, pair|
            result[pair[0].to_sym] = pair[1]
            result
          end
          profile[:name] = profile_name
          credentials[profile_name] = profile
        end
      end
    else
      # Get it to throw an error
      File.open(File.expand_path(credentials_ini_file)) do
      end
    end
    credentials
  end

  def load_aws_credentials
    config_file = ENV['AWS_CONFIG_FILE'] || File.expand_path('~/.aws/config')
    if File.file?(config_file)
      load_aws_ini(config_file)
    else
      raise "AWS config file #{config_file} not found!"
    end
  end

end

# Magic to make these methods injected into the recipe_dsl
Chef::Recipe.send(:include, EcHarness)
Chef::Provider.send(:include, EcHarness)
Chef::Resource.send(:include, EcHarness)
