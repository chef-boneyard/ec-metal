#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

add_command "upgrade", "Upgrade your private chef installation.", 1 do
  reconfigure(false)
  Dir.chdir(File.join(base_path, "embedded", "service", "partybus"))
  bundle = File.join(base_path, "embedded", "bin", "bundle")

  puts 'Waiting for Enterprise Chef to finish starting up'
  sleep 10
  STDOUT.sync = true
  (0..120).each do |attempt|
    break unless is_data_master?
    break if cluster_status_master? && postgres_ready? && erchef_ready?
    sleep 1

    if attempt == 120
      if postgres_ready?
        puts 'WARNING: Timeout waiting for Enterprise Chef to be ready,' +
          ' but PostgreSQL is running so will continue with partybus upgrade'
        break
      else
        puts 'ERROR: Timeout waiting for Enterprise Chef to be ready'
        exit 1
      end
    end
    print '.'
  end

  status = run_command("#{bundle} exec ./bin/partybus upgrade")
  if status.success?
    puts "Chef Server Upgraded!"
    exit 0
  else
    exit 1
  end
end

def postgres_ready?
  pg_cmd = "PGPASSWORD=#{get_secrets['postgresql']['sql_password']} " +
    "/opt/opscode/embedded/bin/psql -h 127.0.0.1 -U opscode_chef " +
    "-c 'select count(*) from users' " +
    "> /dev/null"
  return true if system(pg_cmd)
  false
end

def erchef_ready?
  require 'open-uri'
  require 'openssl'

  begin
    server_status = JSON.parse(
      open('https://localhost/_status',
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
      .read)
  rescue Exception
    return false
  end

  return true if server_status['status'] == 'pong'
  false
end

def get_secrets
  require 'json'
  begin
    JSON.parse(File.read('/etc/opscode/private-chef-secrets.json'))
  rescue Exception => e
    puts 'ERROR: Unable to read /etc/opscode/private-chef-secrets.json, error: ' + e
    exit 1
  end
end

def is_data_master?
  node = get_node

  topology = node['private_chef']['topology']
  role = node['private_chef']['role']

  case topology
  when 'standalone'
    true # by definition
  when 'tier'
    role == 'backend'
  when 'ha'
    if role == 'backend'
      cluster_status_file = ::File.join(node['private_chef']['keepalived']['dir'],
        'current_cluster_status')

      if File.exists?(cluster_status_file)
        File.open(cluster_status_file).read.chomp == 'master'
      end
    else
      false # frontends can't be masters, by definition
    end
  end
end

def get_node
  require 'json'
  begin
    JSON.parse(File.read('/etc/opscode/chef-server-running.json'))
  rescue Exception => e
    puts 'ERROR: Unable to read /etc/opscode/private-chef-secrets.json, error: ' + e
    exit 1
  end
end

def cluster_status_master?
  requested_cluster_status_file = ::File.join(node['private_chef']['keepalived']['dir'],
    'requested_cluster_status')
  return true if
    ::File.exists?(requested_cluster_status_file) &&
    ::File.open(requested_cluster_status_file).read.chomp == 'master'
  false
end
