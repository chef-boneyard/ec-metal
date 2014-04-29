def ipaddresses_prepopulated(private_chef_attributes)
  return true if private_chef_attributes['topology'] == 'ha' &&
    private_chef_attributes['backends'].map { |k,v| v['ipaddress'] }.length == 2 &&
    private_chef_attributes['virtual_hosts'].is_a?(Hash)
  false
end

def hosts_invert(virtual_hosts)
  hosts_inverted = {}
  virtual_hosts.each do |name,ip|
    hosts_inverted[ip] = [] unless hosts_inverted[ip].is_a?(Array)
    hosts_inverted[ip] << name
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

def mydomainname
  node['private-chef']['backends'].
    values.
    first['hostname'].
    split('.')[1..-1].
    join('.')
end

action :create do

  unless ipaddresses_prepopulated(node['private-chef'])

    log "[private-chef::hostsfile] Performing dynamic discovery..."

    %w(backends frontends).each do |whichend|
      node['private-chef'][whichend].each do |vmname,config|
        if vmname == node.name
          ipaddress = node.ipaddress
          log "Using IP address #{ipaddress} for myself: #{vmname}"
        else
          log "Searching for the IP address of #{vmname}"
          ipaddress = search_ipaddress(vmname)
          log "Discovered node #{vmname} IP: #{ipaddress}"
        end
        node.set['private-chef'][whichend][vmname]['ipaddress'] = ipaddress
        node.set['private-chef']['virtual_hosts'][config['hostname']] = ipaddress

        # Hack until we have load balancers
        hostsfile_aliases = []
        if whichend == 'frontends'
          hostsfile_aliases = ["manage.#{mydomainname}", "api.#{mydomainname}"]
        end

        hostsfile_entry ipaddress do
          hostname config['hostname']
          aliases [config['hostname'].split('.').first] + hostsfile_aliases
          comment "Chef private-chef::hostsfile"
          unique true
        end

      end
    end

    # Backend VIP
    hostsfile_entry node['private-chef']['backend_vip']['ipaddress'] do
      hostname node['private-chef']['backend_vip']['hostname']
      aliases [node['private-chef']['backend_vip']['hostname'].split('.').first]
      comment "Chef private-chef::hostsfile"
      unique true
    end

  else
    # Vagrant/prepopulated case
    hosts_invert(node['private-chef']['virtual_hosts']).each do |ip,names|
      shortnames = names.map {|name| name.split('.').first }
      firstname = names.pop

      hostsfile_entry ip do
        hostname firstname
        aliases names + shortnames
        comment "Chef private-chef::hostsfile"
        unique true
      end
    end

  end

end
