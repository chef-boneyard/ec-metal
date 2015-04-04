# encoding: utf-8

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class OpcUsers < Chef::Resource::LWRPBase
      self.resource_name = :opc_users
      actions :create
      default_action :create
      attribute :knife_opc_cmd, :kind_of => String, :default => nil
    end
  end
end

require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class OpcUsers < Chef::Provider::LWRPBase
      use_inline_resources

      action :create do
        domainname = TopoHelper.new(ec_config: node['private-chef']).mydomainname

        directory node['private-chef']['user_root'] do
          action :create
          recursive true
        end

        create_orgs_and_users(
          node['private-chef']['organizations'],
          node['private-chef']['user_root'],
          new_resource.knife_opc_cmd,
          domainname
        )

        file node['private-chef']['users_sentinel_file'] do
          content "Canned dev users and organization created successfully at #{::Time.now}"
          action :create
        end
      end

      def create_orgs_and_users(organizations, user_root, knife_opc_cmd, domainname)
        organizations.each do |orgname, users|
          execute "create_org_#{orgname}" do
            command "#{knife_opc_cmd} org create #{orgname} #{orgname} -f #{user_root}/#{orgname}-validator.pem"
            action :run
            returns [0, 100]
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
              source 'knife.rb.erb'
              variables(
                :username => username,
                :orgname => orgname,
                :server_fqdn => "api.#{domainname}"
              )
              mode '0777'
              action :create
            end

            execute "create_user_#{username}" do
              # it goes USERNAME FIRST_NAME [MIDDLE_NAME] LAST_NAME EMAIL PASSWORD options
              cmd_args = [
                          knife_opc_cmd, 'user', 'create',
                          username, #username
                          username, #first_name
                          username, #last_name
                          "#{username}@#{orgname}.org", #email
                          username, #password
                          '-f' "#{dot_chef}/#{username}.pem"
                         ]
              command cmd_args.join(' ')
              action :run
              returns [0, 100]
            end

            execute "associate_user_#{username}_to_org_#{orgname}" do
              cmd_args = [
                          knife_opc_cmd, 'org', 'user', 'add',
                          orgname,
                          username,
                          '--admin'
                         ]
              command cmd_args.join(' ')
              action :run
            end

          end
        end
      end

    end
  end
end
