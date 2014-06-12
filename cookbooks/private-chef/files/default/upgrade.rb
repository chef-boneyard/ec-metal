#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved
#

require 'open-uri'
require 'openssl'

add_command "upgrade", "Upgrade your private chef installation.", 1 do
  reconfigure(false)
  Dir.chdir(File.join(base_path, "embedded", "service", "partybus"))
  bundle = File.join(base_path, "embedded", "bin", "bundle")

  # Verify that the server is up before continuing
  puts 'Waiting for Enterprise Chef to finish starting up'
  begin
    tries ||= 120
    server_status = JSON.parse(open('https://localhost/_status', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read)
    fail unless server_status['status'] == 'pong'
  rescue Exception
    sleep 1
    if (tries -= 1).zero?
      puts 'Timeout waiting for Enterprise Chef server to start'
      exit 1
    else
      retry
    end
  end

  status = run_command("#{bundle} exec ./bin/partybus upgrade")
  if status.success?
    puts "Chef Server Upgraded!"
    exit 0
  else
    exit 1
  end
end
