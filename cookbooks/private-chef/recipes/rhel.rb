if platform_family?('rhel') 
  remote_file "/tmp/packages@opscode.com.gpg.key" do
    source "https://downloads.getchef.com/chef.gpg.key"
  end

  execute "rpm --import /tmp/packages\@opscode.com.gpg.key"

  directory "/etc/cron.d"

  # Deal with RHEL-based boxes that may have their own firewalls up
  service 'iptables' do
    action [ :disable, :stop ]
  end

  # As of EC11.1.8, we need to disable sudo 'requiretty' on RHEL-based systems
  execute 'sudoers-disable-requiretty' do
    command 'sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers'
    action :run
    only_if 'grep "^Defaults.*requiretty" /etc/sudoers'
  end
end
