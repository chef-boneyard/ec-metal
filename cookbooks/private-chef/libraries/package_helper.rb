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
    '0.0.0'
  end

  def self.private_chef_installed_version(node)
    self.installed_version('private-chef', node)
  end

  def self.osc_version_installed_version(node)
    self.installed_version('chef-server', node)
  end

end
