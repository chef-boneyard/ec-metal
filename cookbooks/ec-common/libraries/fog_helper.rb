# encoding: utf-8

class FogHelper

  attr_accessor :ami, :region

  def initialize(params = {})
    @ami = params[:ami] || 'ami-XXXXXXX'
    @region = params[:region] || 'us-east-1'
  end

  def get_root_blockdevice
    ami_desc = describe_ami.first
    ami_desc['rootDeviceName']
  end

  def describe_ami
    aws = get_aws
    aws.describe_images('ImageId' => @ami).body['imagesSet']
  end

  # refactor me
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

  def get_aws
    require 'fog'
    aws_credentials = load_ini('~/.aws/config')

    Fog::Compute.new(:aws_access_key_id => aws_credentials['default'][:access_key_id],
      :aws_secret_access_key => aws_credentials['default'][:secret_access_key],
      :region => @region || aws_credentials['default'][:region],
      :provider => 'AWS')
  end

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

end