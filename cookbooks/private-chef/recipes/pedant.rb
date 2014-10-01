ruby_block 'run pedant' do
  block do
    STDOUT.sync = true
    shellout_params = {:live_stream => STDOUT}
    if node['osc-install'] 
      cmd = Mixlib::ShellOut.new('/opt/chef-server/bin/chef-server-ctl test; false', shellout_params)
    else
      cmd = Mixlib::ShellOut.new('/opt/opscode/bin/private-chef-ctl test; false', shellout_params)
    end
    if cmd.run_command.status.exitstatus >= 1
      raise Exceptions::ChildConvergeError, "Pedant run failed!"
    end
  end
end
