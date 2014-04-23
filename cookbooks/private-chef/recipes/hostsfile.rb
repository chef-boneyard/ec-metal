# encoding: utf-8

def hosts_invert
  hosts_inverted = {}
  node['private-chef']['virtual_hosts'].each do |name,ip|
    hosts_inverted[ip] = [] unless hosts_inverted[ip].is_a?(Array)
    hosts_inverted[ip] << name
  end
  hosts_inverted
end

if node['private-chef']['virtual_hosts']
  hosts_invert.each do |ip,names|
    shortnames = names.map {|name| name.split('.').first }
    firstname = names.pop
    # # Skip entry if it our node name
    # next if shortnames.include?(node.name)

    hostsfile_entry ip do
      hostname firstname
      aliases names + shortnames
      comment "Chef private-chef::hostsfile"
      unique true
    end
  end
else
  # Dynamic discovery method
  # private_chef_discoverhosts 'foo'
end