
# Load testing Enterprise Chef

## What is it:
Extends `ec-metal` by adding load test machines which run docker via chef-init (chef-container).
The docker machines are left running with a chef-client which checks in every 30 minutes.

## Quick start:
note:  standalone only at this time
example config here: https://github.com/opscode/ec-metal/blob/irving/loadtesters/examples/config.json.loadtesting

loadtester size/count/wave size tuning settings in config.json:
```json
  "loadtesters": {
    "num_loadtesters": 50,
    "num_groups": 5,
    "num_containers": 800
  },
```

1. Bring up a standalone ec-metal server in AWS: `rake up`
2. Bring the load testers online: `rake setup_loadtest`
3. Verify that your loadtesters have all checked in and provided a public IP: `cd users/pinkiepie; knife search node "name:*loadtester*" -a cloud.public_ipv4`
4. Run the load test: `rake run_loadtest`
5. Destroy the loadtest machines after finished: `rake cleanup_loadtest`


## Notes

* Make sure you read and understand what `ec-harness::loadtesters`  and `loadtester_host::default` do
* Review the tuning settings implemented in config.json
* A m3.2xlarge loadtester amazon machine can handle running approx 1000 docker containers running the chef-client cookbook only (daemonized chef-client that runs every 30 minutes)

## Performance Characteristics

* an m3.2xlarge standalone chef server can handle approx 8 simultaneous loadtesting machines firing up docker containers sequentially {1..1000}


## TODO