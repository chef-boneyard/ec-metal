# encoding: utf-8

action :create do
  create_lb unless lb_exists?
  upload_ssl_cert unless ssl_cert_exists?
  create_https_listener unless https_listener_exists?
  register_node unless node_registered?
end

def aws_credentials
  {
    aws_access_key_id: node['cloud']['aws_access_key_id'],
    aws_secret_access_key: node['cloud']['aws_secret_access_key'],
    region: node['cloud']['region']
  }
end

def topology
  TopoHelper.new(ec_config: node['private-chef'])
end

def fog
  FogHelper.new(credentials: aws_credentials)
end

# Use bootstrap_host_name for uniqueness, but dots must be converted to dashes
def elb_name
  topology.bootstrap_host_name.gsub(/[.]/, '-')
end

def create_lb
  log "Creating ELB for #{elb_name}"
  fog.create_elb(
    elb_name,
    node['cloud']['vpc_subnet'] # only map it to the subnet where our cluster lives
  )
end

def lb_exists?
  fog.elb_exists?(elb_name)
end

def create_https_listener
  log "Creating HTTPS listener for ELB #{elb_name}"
  fog
    .get_elb
    .load_balancers
    .get(elb_name)
    .listeners
    .create(
      protocol: 'HTTPS',
      lb_port: 443,
      instance_protocol: 'HTTP',
      instance_port: 80,
      ssl_id: get_ssl_id
    )
  rescue Fog::AWS::IAM::NotFound
    puts "SSL cert #{get_ssl_id} not found yet, sleeping for 5 and retrying"
    sleep 5
    retry
end

def https_listener_exists?
  fog
    .get_elb
    .load_balancers
    .get(elb_name)
    .listeners
    .select { |a| a.protocol == 'HTTPS' }
    .count > 0
end

def upload_ssl_cert
  log "Uploading SSL certificate for #{node['private-chef']['api_fqdn']}"
  api_fqdn = node['private-chef']['api_fqdn']
  pubkey = ::File.read("/var/opt/opscode/nginx/ca/#{api_fqdn}.crt")
  privkey = ::File.read("/var/opt/opscode/nginx/ca/#{api_fqdn}.key")
  fog.get_iam.upload_server_certificate(pubkey, privkey, api_fqdn)
end

def ssl_cert_exists?
   fog
    .get_iam
    .list_server_certificates
    .body['Certificates']
    .select { |a| a['ServerCertificateName'] == node['private-chef']['api_fqdn'] }
    .count > 0
end

def get_ssl_id
  fog
    .get_iam
    .get_server_certificate(node['private-chef']['api_fqdn'])
    .body['Certificate']['Arn'] #FML Excon bs
end

def server_id
  node['chef_provisioning']['reference']['server_id']
end

def register_node
  log "Registering node #{server_id} to ELB #{elb_name}"
  fog
    .get_elb
    .register_instances([server_id], elb_name)
end

def node_registered?
  fog
    .get_elb
    .load_balancers
    .get(elb_name)
    .instances
    .include?(server_id)
end
