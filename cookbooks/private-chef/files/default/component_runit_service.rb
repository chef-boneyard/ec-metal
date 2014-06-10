define :component_runit_service, :log_directory => nil,
                                 :svlogd_size => nil,
                                 :svlogd_num => nil,
                                 :ha => nil,
                                 :control => nil,
                                 :action => :enable do
  component = params[:name]
  log_directory = params[:log_directory] || node['private_chef'][component]['log_directory']

  template "#{log_directory}/config" do
    source "config.svlogd"
    cookbook "enterprise"
    mode "0644"
    owner "root"
    group "root"
    variables(
      :svlogd_size => ( params[:svlogd_size] || node['private_chef'][component]['log_rotation']['file_maxbytes']),
      :svlogd_num  => ( params[:svlogd_num] || node['private_chef'][component]['log_rotation']['num_to_keep'])
    )
  end

  runit_service component do
    action :enable
    retries 20
    control params[:control] if params[:control]
    options(
      :log_directory => log_directory
    )
  end

  if params[:action] == :down
    log "stop runit_service[#{component}]" do
      notifies :down, "runit_service[#{component}]", :immediately
    end
  end

  # Keepalive management
  #
  # Our keepalived setup knows which services it must manage by
  # looking for a 'keepalive_me' sentinel file in the service's
  # directory.
  if EnterpriseChef::Helpers.ha?(node)
    is_keepalive_service = params[:ha] || node['private_chef'][component]['ha']
    file "#{node['runit']['sv_dir']}/#{component}/keepalive_me" do
      action is_keepalive_service ? :create : :delete
    end

    file "#{node['runit']['sv_dir']}/#{component}/down" do
      action is_keepalive_service ? :create : :delete
    end
  end

end
