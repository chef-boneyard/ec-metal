# encoding: utf-8


class FogHelper

  def self.aws_vpc_assign_secondary_ip(provider, region, aws_access_key_id, aws_secret_access_key, server_id, ipaddress)
    require 'fog'
    compute = Fog::Compute.new( :aws_access_key_id => aws_access_key_id,
      :aws_secret_access_key => aws_secret_access_key,
      :region => region,
      :provider => provider)
    backend1 = compute.servers.get(server_id)
    myeni = backend1.network_interfaces.first['networkInterfaceId']
    compute.assign_private_ip_addresses(myeni, 'PrivateIpAddresses' => [ipaddress], 'AllowReassignment' => true)
  end

end