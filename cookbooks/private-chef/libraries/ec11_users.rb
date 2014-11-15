# encoding: utf-8

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class Ec11Users < Chef::Resource::LWRPBase
      self.resource_name = :ec11_users
      actions :create
      default_action :create
    end
  end
end

require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class Ec11Users < Chef::Provider::LWRPBase
      use_inline_resources if defined?(use_inline_resources)

      # from patrick-wright/ec-tools::knife-opc
      knife_opc_cmd = '/opt/opscode/embedded/bin/knife-opc'

      user_root = '/srv/piab/users'
      sentinel_file = '/srv/piab/dev_users_created'
      organizations = {
        'ponyville' => [
            'rainbowdash',
            'fluttershy',
            'applejack',
            'pinkiepie',
            'twilightsparkle',
            'rarity'
        ],
        'wonderbolts' => [
            'spitfire',
            'soarin',
            'rapidfire',
            'fleetfoot'
        ]
      }

      action :create do
        topology = TopoHelper.new(ec_config: node['private-chef'])

        wait_for_ha_master if topology.is_ha?
        wait_for_server_startup

        directory user_root do
          action :create
          recursive true
        end

        create_orgs_and_users

        file sentinel_file do
          content "Canned dev users and organization created successfully at #{Time.now}"
          action :create
        end
      end

      def create_orgs_and_users
        organizations.each do |orgname, users|
          execute "create_org_#{orgname}" do
            command "#{knife_opc_cmd} org create #{orgname} #{orgname} -f #{user_root}/#{orgname}-validator.pem"
            creates "/tmp/something"
            action :run
          end

          users.each do |username|
            folder = "#{user_root}/#{username}"
            dot_chef = "#{folder}/.chef"

            directory dot_chef do
              action :create
              recursive true
            end

            # create a knife.rb file for the user
            template "#{dot_chef}/knife.rb" do
              source "knife.rb.erb"
              variables(
                :username => username,
                :orgname => orgname,
                :server_fqdn => "api.#{topology.mydomainname}"
              )
              mode "0777"
              action :create
            end

            execute "create_user_#{username}_in_org_#{orgname}" do
              # it goes USERNAME FIRST_NAME [MIDDLE_NAME] LAST_NAME EMAIL PASSWORD options
              cmd_args = [
                          knife_opc_cmd, 'user', 'create',
                          username, username, username,
                          "#{username}@#{orgname}.org",
                          username,
                          '-o', orgname,
                          '-f' "#{dot_chef}/#{username}.pem"
                         ]
              command cmd_args.join(' ')
              action :run
            end
          end
        end
      end

      def wait_for_ha_master
        Chef::Log.info('Waiting for node to become HA master')
        attempts = 600
        STDOUT.sync = true

        keepalived_dir = '/var/opt/opscode/keepalived'
        requested_cluster_status_file = ::File.join(keepalived_dir, 'requested_cluster_status')
        cluster_status_file = ::File.join(keepalived_dir, 'current_cluster_status')

        (0..attempts).each do |attempt|
          break if File.exists?(requested_cluster_status_file) &&
            File.open(requested_cluster_status_file).read.chomp == 'master' &&
            File.exists?(cluster_status_file) &&
            File.open(cluster_status_file).read.chomp == 'master'

          sleep 1
          print '.'
          if attempt == attempts
            raise "I'm sick of waiting for server startup after #{attempt} attempts"
          end
        end
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
            raise "I'm sick of waiting for server startup after #{attempt} attempts"
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