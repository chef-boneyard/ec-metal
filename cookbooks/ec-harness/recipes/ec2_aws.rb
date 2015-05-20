# encoding: utf-8

require 'chef/provisioning/aws_driver'

harness_dir = node['harness']['harness_dir']
repo_path = node['harness']['repo_path']

with_chef_local_server :chef_repo_path => repo_path,
  :cookbook_path => [ File.join(harness_dir, 'cookbooks'),
                      File.join(repo_path, 'cookbooks'),
                      File.join(repo_path, 'vendor', 'cookbooks') ],
  :port => 9010.upto(9999)

with_driver "aws:default:#{node['harness']['ec2']['region']}"

# override all keypair settings if passed as env var
node.set['harness']['ec2']['keypair_name'] = ENV['ECM_KEYPAIR_NAME'] unless ENV['ECM_KEYPAIR_NAME'].nil?

keypair_name = node['harness']['ec2']['keypair_name'] || "#{ENV['USER']}@#{::File.basename(harness_dir)}"

aws_key_pair keypair_name do
  private_key_path File.join(repo_path, 'keys', 'id_rsa')
  public_key_path File.join(repo_path, 'keys', 'id_rsa.pub')
end

