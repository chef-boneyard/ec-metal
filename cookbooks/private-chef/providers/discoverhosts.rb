# encoding: utf-8

def topo
  TopoHelper.new(ec_config: node['private-chef'])
end

def api_hostname
  "api.#{topo.mydomainname}"
end

def ipaddresses_prepopulated(private_chef_attributes)
  case private_chef_attributes['topology']
  when 'ha', 'tier'
    return true if private_chef_attributes['backends'].map { |k,v| v['ipaddress'] }.length >= 1 &&
      private_chef_attributes['virtual_hosts'].is_a?(Hash)
  else
    return true if private_chef_attributes['virtual_hosts'].is_a?(Hash)
  end
  false
end

def hosts_invert(virtual_hosts)
  hosts_inverted = {}
  virtual_hosts.each do |name,ip|
    hosts_inverted[ip] = [] unless hosts_inverted[ip].is_a?(Array)
    hosts_inverted[ip] << name unless name == api_hostname
  end
  hosts_inverted
end

def search_ipaddress(vmname)
  result = search(:node, "name:#{vmname}").first
  if result && result['ipaddress']
    return result['ipaddress']
  else
    return '127.0.0.2'
  end
end

action :create do

  unless ipaddresses_prepopulated(node['private-chef'])

    log "[private-chef::hostsfile] Performing dynamic discovery..."

    topo.found_topo_types.each do |whichend|
      node['private-chef'][whichend].each do |vmname, config|
        if vmname == node.name
          ipaddress = node.ipaddress
          log "Using IP address #{ipaddress} for myself: #{vmname}"

          # set a "special" alias pointed at ourself
          if topo.is_analytics?(node.name)
            hostsfile_aliases = ["analytics.#{topo.mydomainname}"]
          else
            # point the API fqdn at myself on each host, so p-c-c test runs against me
            hostsfile_aliases = ["api.#{topo.mydomainname}"]
          end

        else
          log "Searching for the IP address of #{vmname}"
          ipaddress = search_ipaddress(vmname)
          log "Discovered node #{vmname} IP: #{ipaddress}"

          # on analytics nodes, point api. at the frontend
          if topo.is_analytics?(node.name) && topo.is_frontend?(vmname)
            hostsfile_aliases = ["api.#{topo.mydomainname}"]
          else
            hostsfile_aliases = []
          end
        end
        node.set['private-chef'][whichend][vmname]['ipaddress'] = ipaddress


        hostsfile_entry ipaddress do
          hostname config['hostname']
          aliases [config['hostname'].split('.').first] + hostsfile_aliases
          comment "Chef private-chef::hostsfile"
          unique true
        end
      end
    end

    # Backend VIP, required for HA only
    if node['private-chef']['topology'] == 'ha'
      hostsfile_entry node['private-chef']['backend_vip']['ipaddress'] do
        hostname node['private-chef']['backend_vip']['hostname']
        aliases [node['private-chef']['backend_vip']['hostname'].split('.').first]
        comment "Chef private-chef::hostsfile"
        unique true
      end
    end

  else
    # Vagrant/prepopulated case
    hosts_invert(node['private-chef']['virtual_hosts']).each do |ip,names|
      shortnames = names.map {|name| name.split('.').first }
      firstname = names.pop

      # point the API fqdn at myself on each host, so p-c-c test runs against me
      # Not sure if it's more reliable to match node.name from shortnames or
      #  node.fqdn from names -- we shall see
      if shortnames.include?(node.name)
        names << api_hostname
      end

      hostsfile_entry ip do
        hostname firstname
        aliases names + shortnames
        comment "Chef private-chef::hostsfile"
        unique true
      end
    end

  end

end
