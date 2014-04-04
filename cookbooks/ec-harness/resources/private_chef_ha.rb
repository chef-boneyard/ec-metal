actions [:install, :upgrade, :stop_all_but_master, :destroy]

default_action :install

attribute :ec_package, :kind_of => String