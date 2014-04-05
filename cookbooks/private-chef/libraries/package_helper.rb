# encoding: utf-8

class PackageHelper

  def self.pc_version(package)
    # ex: private-chef-11.0.2-1.el6.x86_64.rpm
    #  or private-chef-1.4.6-1.el6.x86_64
    return '0.0.0' unless package =~ /^private-chef/
    package.split('-')[2]
  end

  # TODO: Make this work for Ubuntu/Debian as well
  def self.private_chef_installed
    rpmq = `rpm -q private-chef`
    if rpmq =~ /^private-chef-/
      return rpmq
    else
      return nil
    end
  end

  def self.private_chef_installed_version
    pc_version(private_chef_installed)
  end

end