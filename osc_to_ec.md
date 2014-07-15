# Steps for running osc to ec in ec-metal
Instead of building auto-detection logic for osc and ec packages and futher clutter the code due to the osc hacks two new config attributes were added:

osc_install and osc_upgrade (they are mutually exclusive)

see config example config files centos6-osc-vbox.json and centos6-ec-vbox.json

config file known issues:
- although the osc to ec paths don't use backends or frontends the empty arrays are required ( not to tear down the code base)
- manage will be required with Chef 12, will add that to the template when the manage and chef 12 integration is complete

this branch supports a env var to configure the "config.json" file name

Once the packages on interest are available run this:

install osc 

```ECM_CONFIG=config-osc.json CACHE_PATH=~/Chef/packages rake up```


upgrade to ec

```ECM_CONFIG=config-ec.json CACHE_PATH=~/Chef/packages rake up```

use `rake up for both executions` and change the ECM_CONFIG value


## pedant

Automatically run pedant at the end of the provision phase by setting `run_pedant` attribute to true

## note upgrade_torture
won't work, don't try it.