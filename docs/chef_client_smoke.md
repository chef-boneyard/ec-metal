# Converge a node
---
After having stood up a chef server with `ec-metal` (possibly before upgrading it), you'll want to verify that it functions as expected. Namely, by converging a node against it. We can thankfully leverage the `starter kit` built into the webui to pull down a pre-configured chef-repo.

1. Ensure the webui is installed:

	- Chef Server 12: `chef-server-ctl install opscode-manage`
	- Enterprise Chef: You will need to specify a `"manage_package": "path/to/package.deb"` within the top-level of your configuration file, or acquire and install the `opscode-manage` package manually
	- Open Source: The old webui **does not** include the starter-kit, these instructions are not for you.
	
1. Create a user, either via the webui of via the `chef-server-ctl user-create` command

	- `chef-server-ctl user-create testuser existing user username@email.con 123\!Opscode`

2. Log into the webui as that user
3. Navigate to **Administration** > select an org (center pane) > **Starter Kit** (left)
4. Unpack the provided `chef-starter.zip` (it will expand to become a `chef-repo` directory)
5. `cd chef-repo`
6. We can abuse the `Vagrantfile` and `knife.rb` that comes in the `starter-kit` to turn on a Vagrant VM and bootstrap it against our test chef server:

```
vagrant up --provider=virtualbox && vagrant ssh -c "echo \"33.33.36.23    api1004.ubuntu.vagrant\" | sudo tee -a /etc/hosts"; knife bootstrap 127.0.0.1 -x vagrant -P vagrant -p $(vagrant ssh-config | grep "Port" | awk '{print $2}') --sudo -r ""
```

**NOTE**: You will need to edit the `33.33.36.23    api1004.ubuntu.vagrant` line within the above that is being written to the /etc/hosts file of the Vagrant VM such that the VM will be able to resolve the chef server url specified within `../chef-repo/.chef/knife.rb` (which we are using to bootstrap, and therefore create the `client.rb` on the VM).