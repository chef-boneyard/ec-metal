# encoding: utf-8

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class OrgTorturer < Chef::Resource::LWRPBase
      self.resource_name = :org_torturer
      actions :create
      default_action :create
      attribute :knife_opc_cmd, :kind_of => String, :default => nil
    end
  end
end

require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class OrgTorturer < Chef::Provider::LWRPBase
      use_inline_resources

      ADMIN_USER = 'pinkiepie'
      NUM_ORGS = 900

      action :create do
        USER_ROOT = node['private-chef']['user_root']
        DOMAIN_NAME = TopoHelper.new(ec_config: node['private-chef']).mydomainname
        KNIFE_OPC_CMD = new_resource.knife_opc_cmd

        directory USER_ROOT do
          action :create
          recursive true
        end

        generate_orgs(1..NUM_ORGS)
      end

      def generate_orgs(organizations)
        organizations.each do |orgname|
          create_org("org#{orgname}")
        end
      end

      def create_org(orgname)
        validator_file = "#{USER_ROOT}/#{orgname}-validator.pem"
        execute "create_org_#{orgname}" do
          command "#{KNIFE_OPC_CMD} org create #{orgname} #{orgname} -f #{validator_file}"
          action :run
          not_if "test -f #{validator_file}"
          notifies :run, "execute[associate_user_#{ADMIN_USER}_to_org_#{orgname}]", :immediately
        end

        execute "associate_user_#{ADMIN_USER}_to_org_#{orgname}" do
          cmd_args = [
                      KNIFE_OPC_CMD, 'org', 'user', 'add',
                      orgname,
                      ADMIN_USER,
                      '--admin'
                     ]
          command cmd_args.join(' ')
          action :nothing
        end
      end

    end
  end
end
