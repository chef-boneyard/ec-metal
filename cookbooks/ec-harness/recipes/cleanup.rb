# encoding: utf-8

harness = data_bag_item 'harness', 'config'

include_recipe "ec-harness::#{harness['provider']}"

ec_harness_private_chef_ha "destroy_#{harness['default_package']}_on_#{harness['provider']}" do
  action :destroy
end

if harness['provider'] == 'ec2' && harness['ec2']['backend_storage_type'] == 'ebs'

  ruby_block 'destroy_ebs_volume' do
    block do
      # get the EBS data volume id
      topology = TopoHelper.new(ec_config: harness['vm_config'])

      begin
        item = data_bag_item('ebs_volumes_db', topology.bootstrap_host_name)
        ebs_vol_id = item['volume_id']
      rescue Net::HTTPServerException
        Chef::Log.info("Databag ebs_volumes_db not found, continuing")
      end

      if ebs_vol_id
        fog_helper = FogHelper.new(region: harness['ec2']['region'])
        begin
          fog_helper.get_aws.delete_volume(ebs_vol_id)
          num_attempts ||= 0
        rescue Fog::Compute::AWS::Error => e
          num_attempts += 1
          raise e if num_attempts > 5

          # typically due to volume still attached, machine shutting down
          Chef::Log.info("AWS error, sleeping and then retrying: #{e}")
          sleep 5
          retry
        rescue Fog::Compute::AWS::NotFound
          # because the volume doesn't exist
          Chef::Log.info("Volume not found, continuing")
        end
      end
    end
  end

  ruby_block 'delete_ebs_volumes_databag_item' do
    block do
      begin
        ebs_volumes_db = Chef::DataBag.new
        ebs_volumes_db.name('ebs_volumes_db')
        ebs_volumes_db.destroy
        # can't destroy an item because https://github.com/opscode/chef-zero/issues/82
        # item = data_bag_item('ebs_volumes_db', topology.bootstrap_host_name)
        # item.destroy
      rescue Net::HTTPServerException => e
        Chef::Log.info("Databag ebs_volumes_db not found, continuing: #{e}")
      end
    end
  end

end
if harness['provider'] == 'ec2' && harness['ec2']['backend_storage_type'] == 'ebs'

  ruby_block 'destroy_ebs_volume' do
    block do
      # get the EBS data volume id
      topology = TopoHelper.new(ec_config: harness['layout'])

      begin
        item = data_bag_item('ebs_volumes_db', topology.bootstrap_host_name)
        ebs_vol_id = item['volume_id']
      rescue Net::HTTPServerException
        Chef::Log.info("Databag ebs_volumes_db not found, continuing")
      end

      if ebs_vol_id
        fog_helper = FogHelper.new(region: harness['ec2']['region'])
        begin
          fog_helper.get_aws.delete_volume(ebs_vol_id)
          num_attempts ||= 0
        rescue Fog::Compute::AWS::Error => e
          num_attempts += 1
          raise e if num_attempts > 5

          # typically due to volume still attached, machine shutting down
          Chef::Log.info("AWS error, sleeping and then retrying: #{e}")
          sleep 5
          retry
        rescue Fog::Compute::AWS::NotFound
          # because the volume doesn't exist
          Chef::Log.info("Volume not found, continuing")
        end
      end
    end
  end

  ruby_block 'delete_ebs_volumes_databag_item' do
    block do
      begin
        ebs_volumes_db = Chef::DataBag.new
        ebs_volumes_db.name('ebs_volumes_db')
        ebs_volumes_db.destroy
        # can't destroy an item because https://github.com/opscode/chef-zero/issues/82
        # item = data_bag_item('ebs_volumes_db', topology.bootstrap_host_name)
        # item.destroy
      rescue Net::HTTPServerException => e
        Chef::Log.info("Databag ebs_volumes_db not found, continuing: #{e}")
      end
    end
  end

end
