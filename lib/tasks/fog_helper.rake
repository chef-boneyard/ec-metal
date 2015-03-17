# encoding: utf-8

def get_running_server_ips(region)
  require_relative '../../cookbooks/ec-common/libraries/fog_helper'

  compute = FogHelper.new(region: region).get_aws
  compute.servers.all.
    select { |server| server.state == "running" }.
    map { |server| { 'name' => server.tags['Name'],
      'ipaddress' => server.public_ip_address,
      'hostname' => server.dns_name } }
end


def fog_populate_ips(config)
  require_relative '../../cookbooks/ec-common/libraries/topo_helper'

  get_running_server_ips(config['ec2_options']['region']).each do |entry|

    topo = TopoHelper.new(ec_config: config['layout'], exclude_layers: ['loadtesters'])
    topo.found_topo_types.each do |whichend|
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

      if whichend == 'analytics_frontends'
        config['layout']['virtual_hosts'][config['layout']['analytics_fqdn']] = entry['ipaddress']
      end

      if whichend == 'analytics_standalones'
        config['layout']['virtual_hosts'][config['layout']['analytics_fqdn']] = entry['ipaddress']
      end

      if whichend == 'standalones'
        config['layout']['virtual_hosts'][config['layout']['manage_fqdn']] = entry['ipaddress']
        config['layout']['virtual_hosts'][config['layout']['api_fqdn']] = entry['ipaddress']
        config['layout']['virtual_hosts'][config['layout']['analytics_fqdn']] = entry['ipaddress']
      end

    end
  end
  config
end
