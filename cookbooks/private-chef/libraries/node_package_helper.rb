# encoding: utf-8

module EcMetal
  class NodePackage

    attr_reader :osc_version, :ec_version

    def initialize(node)
      @node = node
      @osc_version = open_source_chef_installed_version
      @ec_version = private_chef_installed_version
    end

    def chef_installed?
      @osc_version || @ec_version
    end

    def private_chef_installed?
      false if @osc_version.nil?
    end

    def open_source_chef_installed?
      false if @ec_version.nil?
    end
    
    private

    def installed_version(package_prefix)
      version = nil

      # Chef magic to get the package version in a cross-platform fashion
      pkg = Chef::Resource::Package.new(package_prefix, @node)
      pkg_provider = Chef::Platform.provider_for_resource(pkg)
      pkg_provider.load_current_resource

      if pkg_provider.current_resource.version
        version = pkg_provider.current_resource.version
          .gsub(/[_+]/, '-')
          .split('-')
          .first
      end
      
      raise ArgumentError "#{package_prefix} not installed on #{@node}" unless version
      
      return version
    end

    def private_chef_installed_version
      begin
        return installed_version('private-chef')
      rescue
        # how do I log to the  chef-client from here?
        return nil
      end
    end

    def open_source_chef_installed_version
      begin
        return installed_version('chef-server')
      rescue
        # how do I log to the  chef-client from here?
        return nil
      end
    end
  end
end