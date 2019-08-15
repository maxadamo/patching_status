# patching_status

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup - The basics of getting started with galera_proxysql](#setup)
    * [Setting up patching_status](#setting-up-patching_status)
1. [Credits - jQuery and CSS acknowledgements](#credits)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

The modules will set up a page which shows the patching status, based on the data that you feed on the puppetDB through the puppet module: albatrossflavour/os_patching
This module will only copy the files that will be accessed by a web server.

## Requirements

* Your web server of choice points to the destination directory
* Your systems are already sending the patch status to the PuppetDB using the module `albatrossflavour/os_patching`

## Setup

### Setting up patching_status

Sensitive type for passwords is not mandatory, but it's recommended. If it's not being used the module will emit a notifycation.

To setup the web page:

```puppet
class { '::patching_status':
  Optional[Stdlib::Absolutepath] $destination = undef,
  String $user = $patching_status::params::user,
  String $group = $patching_status::params::group,
  String $cron_hour = $patching_status::params::cron_hour,
  String $cron_minute = $patching_status::params::cron_minute,
  Enum['ensure_packages', 'package'] $install_method = $patching_status::params::install_method,

  destination     => /destination/directory, # Mandatory
  user            => 'root',                 # Optional
  group           => 'root,                  # Optional
  cron_hour       => '*',                    # Optional
  cron_minutes    => fqdn_rand('60'),        # Optional
  ensure_packages => 'package';              # Optional
}
```

## Credits

Mountable: iQuery json to table by [Guilherme Augusto Madaleno](https://github.com/guimadaleno/mountable)

Web Page spinner: by [Pace](https://github.hubspot.com/pace/docs/welcome/)

PuppetForge module: [os_patching](https://forge.puppet.com/albatrossflavour/os_patching)

## Limitations

Supports Ubuntu 16.04, 18.04 and CentOS 7
