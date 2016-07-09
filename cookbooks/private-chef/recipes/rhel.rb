if platform_family?('rhel')
  remote_file "/tmp/packages@opscode.com.gpg.key" do
    source "https://downloads.getchef.com/packages-chef-io-public.key"
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

  # RHEL and it's silly limits
  file '/etc/security/limits.d/90-nproc.conf' do
    action :delete
  end

  file '/etc/security/limits.d/10-nofile.conf' do
    action :create
    owner 'root'
    group 'root'
    mode '0644'
    content "*          soft    nofile     1048576\n*          hard    nofile     1048576"
  end

  include_recipe 'yum-epel'

  package 'atop'
  package 'telnet'
  package 'nc'
end
