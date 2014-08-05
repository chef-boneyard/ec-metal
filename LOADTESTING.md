
# Load testing Enterprise Chef

## What is it:
Extends `ec-metal` by adding load test machines which run docker via chef-init (chef-container).
The docker machines are left running with a chef-client which checks in every 30 minutes.

## Quick start:
note:  standalone only at this time
example config here: https://github.com/opscode/ec-metal/blob/irving/loadtesters/examples/config.json.loadtesting

1. Bring up a standalone ec-metal server in AWS: `rake up`
2. Bring the load testers online: `rake loadtesters`
3. Verify that your loadtesters have all checked in and provided a public IP: `cd users/pinkiepie; knife search node "name:*loadtester*" -a cloud.public_ipv4`
4. Run the load test: `rake run_loadtest`
5. Destroy the loadtest machines after finished: `rake cleanup_loadtest`


## Notes

* Make sure you read and understand what `ec-harness::loadtesters`  and `docker_host::default` do
* Review the tuning settings implemented in config.json
* Additional tuning is needed to handle large amounts of registering nodes, namely increasing `default['private_chef']['oc_chef_authz']['http_init_count']` and `default['private_chef']['oc_chef_authz']['http_max_count']` (cannot be tweaked in `private-chef.rb`, need to change the attributes/default file yourself)
* A m3.2xlarge amazon machine can handle approx 2000 docker containers running chef-client


## TODO

* Add amazon ELB functionality to test in a Tier topology
* Make the number of loadtesters and number of loadtest containers tunable