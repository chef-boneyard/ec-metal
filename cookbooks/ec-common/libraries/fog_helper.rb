# encoding: utf-8

class FogHelper

  attr_accessor :ami, :region, :credentials

  def initialize(params = {})
    @ami = params[:ami] || 'ami-XXXXXXX'
    @region = params[:region] || nil
    @credentials = params[:credentials] || load_ini
  end

  def create_elb(id, subnet_id)
    @elb ||= get_elb
    @elb.load_balancers.create(
      id: id,
      listeners: [
        {
          protocol: 'HTTP',
          lb_port: 80,
          instance_protocol: 'HTTP',
          instance_port: '80'
        }
      ],
      subnet_ids: [subnet_id]
    )
  end

  def get_az_of_subnet(subnet_id)
    @aws ||= get_aws
    @aws
      .subnets
      .get(subnet_id)
      .availability_zone
  end

  def elb_exists?(id)
    @elb ||= get_elb
    @elb.load_balancers.get(id) ? true : false
  end

  def get_elb_dns_name(id)
    @elb ||= get_elb
    @elb.load_balancers.get(id).dns_name
  rescue
    'notcreatedyet'
  end

  def get_root_blockdevice
    puts "If you see me more than once, I should be memoized! #{@ami}"
    ami_desc = describe_ami.first
    ami_desc['blockDeviceMapping'].
      select { |dev| dev['deviceName'] =~ /sda/ }.
      first['deviceName']
  end

  def describe_ami
    @aws ||= get_aws
    @aws.describe_images('ImageId' => @ami).body['imagesSet']
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

  def get_iam
    require 'fog'
    Fog::AWS::IAM.new(:aws_access_key_id => @credentials[:aws_access_key_id],
      :aws_secret_access_key => @credentials[:aws_secret_access_key])
  end

  def get_elb
    require 'fog'
    Fog::AWS::ELB.new(:aws_access_key_id => @credentials[:aws_access_key_id],
      :aws_secret_access_key => @credentials[:aws_secret_access_key],
      :region => @region || @credentials[:region])
  end

  def get_aws
    require 'fog'
    Fog::Compute.new(:aws_access_key_id => @credentials[:aws_access_key_id],
      :aws_secret_access_key => @credentials[:aws_secret_access_key],
      :region => @region || @credentials[:region],
      :provider => 'AWS')
  end

  def load_ini(credentials_ini_file='~/.aws/config', ini_profile='default')
    require 'inifile'
    credentials = {}
    inifile = IniFile.load(File.expand_path(credentials_ini_file))
    inifile.each_section do |section|
      if section =~ /^\s*profile\s+(.+)$/ || section =~ /^\s*(default)\s*/
        profile = $1.strip
        credentials[profile] = {
          :aws_access_key_id => inifile[section]['aws_access_key_id'],
          :aws_secret_access_key => inifile[section]['aws_secret_access_key'],
          :region => inifile[section]['region']
        }
      end
    end
    credentials[ini_profile]
  end

end
