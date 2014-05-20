# encoding: utf-8

class FogHelper

  def self.load_ini(credentials_ini_file)
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

  def self.get_aws
    require 'fog'
    aws_credentials = load_ini('~/.aws/config')

    Fog::Compute.new(:aws_access_key_id => aws_credentials['default'][:access_key_id],
      :aws_secret_access_key => aws_credentials['default'][:secret_access_key],
      :region => aws_credentials['default'][:region],
      :provider => 'AWS')
  end

  def self.describe_ami(ami)
    aws = get_aws
    aws.describe_images('ImageId' => ami).body['imagesSet']
  end

  def self.get_root_blockdevice(ami)
    ami = describe_ami(ami).first
    ami['blockDeviceMapping'].
      select { |dev| dev['deviceName'] =~ /sda/ }.
      first['deviceName']
  end

end