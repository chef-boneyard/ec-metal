# encoding: utf-8

class DrbdHelper

  def self.get_drbdadm_version
    `modinfo -F version drbd`
  end

end