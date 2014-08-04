# encoding: utf-8

# Used with permission from Hosh:
# https://github.com/hosh/chef-server-test/blob/master/lib/chef-server-test/package_info.rb
module EcMetal
  class ChefPackageInfo

    attr_reader :package_name, :version, :server_type

    def valid?
      !match_data.nil? and (platform == 'ubuntu' && package_type == 'deb') || (platform == 'el' && package_type == 'rpm')
    end

    def to_hash
      {
        'version'          => @version,
        'platform'         => @platform,
        'platform_version' => @platform_version,
        'platform_info'    => @platform_info,
        'arch'             => @arch,
        'server_type'      => @server_type
      }
    end

    def server_type_sym(data)
      type = nil
      if data == 'private-chef'
        type = :ec
      elsif data == 'chef-server'
        type = :osc
      end

      type
    end

    # Sample package name:
    # chef-server_11.0.8+20140213205408.git.96.207d16a-1.ubuntu.10.04_amd64.deb
    def initialize(package_name)
      @package_name = package_name
      @matcher = /^(chef-server|private-chef)[-_](\d+\.\d+\.\d+).*(ubuntu\.\d+\.\d+|el\d+)[._](\S+)\.(deb|rpm)$/
      @match_data = @matcher.match(package_name)
      @server_type = server_type_sym(@match_data[1])
      @version, @platform_info, @arch, @package_type = @match_data[2, 3, 4, 5]
      @platform = /(ubuntu|el)/.match(@platform_info)[1]
      @platform_version = /(ubuntu\.|el)([0-9.]+)/.match(@platform_info)[2]
    end
  end
end
