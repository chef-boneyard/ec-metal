# encoding: utf-8

class DrbdHelper

  def self.get_drbdadm_version
    if File.exists?('/sbin/drbdadm') || File.exists?('/usr/sbin/drbdadm')
      drbdadm_version = `drbdadm --version`.
        split("\n").
        select { |line| line =~ /^DRBDADM_VERSION=/ }.
        first.
        split('=')[1]
    else
      drbdadm_version = nil
    end
    drbdadm_version
  end

end