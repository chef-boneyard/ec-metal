# encoding: utf-8

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class WaitForServerReady < Chef::Resource::LWRPBase
      self.resource_name = :wait_for_server_ready
      actions :create
      default_action :create
    end
  end
end

require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class WaitForServerReady < Chef::Provider::LWRPBase
      use_inline_resources

      action :create do
        wait_for_server_startup
      end

      def wait_for_server_startup
        Chef::Log.info('Waiting for the Chef server to be ready')
        attempts = 90
        STDOUT.sync = true
        (0..attempts).each do |attempt|
          break if erchef_ready?

          sleep 1
          print '.'
          if attempt == attempts
            raise "Gave up waiting for the Chef server to be ready after #{attempt} attempts"
          end
        end
      end

      def erchef_ready?
        require 'open-uri'
        require 'openssl'

        begin
          server_status = JSON.parse(open('https://localhost/_status', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read)
        rescue Exception
          return false
        end

        return true if server_status['status'] == 'pong'
        false
      end

    end
  end
end