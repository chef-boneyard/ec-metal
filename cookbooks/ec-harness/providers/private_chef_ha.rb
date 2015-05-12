# encoding: utf-8

def whyrun_supported?
  true
end

use_inline_resources

action :cloud_create do
  log "action :cloud_create, I don't do anything anymore!"
end

action :install do
  log "action :install, I don't do anything anymore!"
end

action :pedant do
  log "action :pedant, I don't do anything anymore!"
end

# bin/knife opc -c chef-repo/pivotal/knife-pivotal.rb user list
action :pivotal do
  log "action :pivotal, I don't do anything anymore!"
end

action :stop_all_but_master do
  log "action :stop_all_but_master, I don't do anything anymore!"
end

action :start_non_bootstrap do
  log "action :start_non_bootstrap, I don't do anything anymore!"
end

action :destroy do
  log "action :destroy, I don't do anything anymore!"
end


