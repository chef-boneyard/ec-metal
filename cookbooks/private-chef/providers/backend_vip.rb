# encoding: utf-8

# For cloud providers where ARP doesn't work, initially works in AWS VPC

action :create do
  aws_access_key_id = node['cloud']['aws_access_key_id']
  aws_secret_access_key = node['cloud']['aws_secret_access_key']
  region = node['cloud']['region']
  server_id = node['chef_provisioning']['reference']['server_id']
  ipaddress = node['private-chef']['backend_vip']['ipaddress']

  FogHelper.aws_vpc_assign_secondary_ip('AWS', region, aws_access_key_id, aws_secret_access_key, server_id, ipaddress)
  log "Assigned backend_vip #{ipaddress} to server #{server_id}"
  new_resource.updated_by_last_action(true)
end


