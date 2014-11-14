# encoding: utf-8

class PackageHelper

  def self.package_version(package)
    version = '0.0.0'
    if ( (package =~ /^private-chef/) || (package =~ /^chef-server-(\d+)/) )
      version = package.gsub(/[_+%]/, '-').split('-')[2]
    elsif package =~ /^chef-server-core/
      version = package.gsub(/[_+%]/, '-').split('-')[3]
    else
      return version
    end
  end

  def self.installed_version(package, node)
    # Chef magic to get the package version in a cross-platform fashion
    pkg = Chef::Resource::Package.new(package, node)
    pkg_provider = Chef::Platform.provider_for_resource(pkg)
    begin
      pkg_provider.load_current_resource
    rescue Chef::Exceptions::Package
      return '0.0.0'
    end

    if pkg_provider.current_resource.version
      pkg_provider.current_resource.version
        .gsub(/[_+]/, '-')
        .split('-')
        .first
    else
      '0.0.0'
    end
  end

  def self.private_chef_installed_version(node)
    private_chef_version = self.installed_version('private-chef', node)
    private_chef_version != '0.0.0' ?  private_chef_version : self.installed_version('chef-server-core', node)
  end

  def self.osc_version_installed_version(node)
    self.installed_version('chef-server', node)
  end

end
