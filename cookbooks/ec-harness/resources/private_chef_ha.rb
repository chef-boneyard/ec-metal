actions [:install, :cloud_create, :stop_all_but_master, :start_non_bootstrap, :destroy, :pedant]

default_action :install

attribute :ec_package, :kind_of => String