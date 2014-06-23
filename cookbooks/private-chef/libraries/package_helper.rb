# encoding: utf-8

class PackageHelper
  def self.pc_version(package)
    # ex: private-chef-11.0.2-1.el6.x86_64.rpm
    #  or private-chef-1.4.6-1.el6.x86_64
    return '0.0.0' unless package =~ /^private-chef/
    package
      .gsub(/[_+%]/, '-')
      .split('-')[2]
  end

  def self.private_chef_installed_version(node)
    # Chef magic to get the package version in a cross-platform fashion
    pkg = Chef::Resource::Package.new('private-chef', node)
    pkg_provider = Chef::Platform.provider_for_resource(pkg)
    pkg_provider.load_current_resource

    if pkg_provider.current_resource.version
      pkg_provider.current_resource.version
        .gsub(/[_+]/, '-')
        .split('-')
        .first
    else
      '0.0.0'
    end
  end
end
