# encoding: utf-8

def load_ini(credentials_ini_file)
  require 'inifile'
  credentials = {}
  inifile = IniFile.load(File.expand_path(credentials_ini_file))
  inifile.each_section do |section|
    if section =~ /^\s*profile\s+(.+)$/ || section =~ /^\s*(default)\s*/
      profile = $1.strip
      credentials[profile] = {
        :access_key_id => inifile[section]['aws_access_key_id'],
        :secret_access_key => inifile[section]['aws_secret_access_key'],
        :region => inifile[section]['region']
      }
    end
  end
  credentials
end

def get_aws
  require 'fog'
  aws_credentials = load_ini('~/.aws/config')

  Fog::Compute.new(:aws_access_key_id => aws_credentials['default'][:access_key_id],
    :aws_secret_access_key => aws_credentials['default'][:secret_access_key],
    :region => aws_credentials['default'][:region],
    :provider => 'AWS')
end

def get_running_server_ips
  compute = get_aws
  compute.servers.all.
    select { |server| server.state == "running" }.
    map { |server| { 'name' => server.tags['Name'],
      'ipaddress' => server.public_ip_address,
      'hostname' => server.dns_name } }
end


def fog_populate_ips(config)
 get_running_server_ips.each do |entry|
    puts "node #{entry['name']} ip #{entry['ipaddress']}"
    %w(backends frontends).each do |whichend|
      next unless config['layout'][whichend][entry['name']]
      config['layout'][whichend][entry['name']]['ipaddress'] = entry['ipaddress']

      # for create_hosts_entries
      config['layout']['virtual_hosts'] = {} unless config['layout']['virtual_hosts']
      config['layout']['virtual_hosts'][config['layout'][whichend][entry['name']]['hostname']] = entry['ipaddress']

      # webui entries
      if whichend == 'frontends'
        config['layout']['virtual_hosts'][config['layout']['manage_fqdn']] = entry['ipaddress']
        config['layout']['virtual_hosts'][config['layout']['api_fqdn']] = entry['ipaddress']
      end

    end
  end
  config
end
