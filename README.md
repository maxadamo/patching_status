# patching_status

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup - The basics of getting started with galera_proxysql](#setup)
    * [Setting up patching_status](#setting-up-patching_status)
1. [Screenshot](#screenshot)
1. [Credits - jQuery and CSS acknowledgements](#credits)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module sets up a the web pages to show the patching status of your systems. The data are fed to PuppetDB through the scripts provided by the module: albatrossflavour/os_patching. This modules pulls the data from the PuppetDB and convert them in HTML format.
The module will only copy the files that will be accessed by a web server.

## Requirements

* Your web server of choice points to the destination directory
* Your systems are already sending the patch status to the PuppetDB using the module `albatrossflavour/os_patching`

## Setup

### Setting up patching_status

This example will setup the web page:

```puppet
class { '::patching_status':
  web_base    => /virtualenv/directory,
  python_base => /webserver/directory,
  puppetdb    => '192.168.1.10';
}
```

Other parameters include:

* puppetdb port (default: 8080)
* cron_hour (default: every hour)
* cron_minute (default: once in 1 hour)
* user (default: root. User to assign the files to and install the cron job)
* group (default: root. Group to assign the files to)
* install_method (default: ensure_packages. You can choose between `ensure_packages` and `package`. You can try the default first)

## Screenshot

![Screenshot N/A](https://wiki.geant.org/download/attachments/126981072/patching_status.png  "Patching Status")

## Credits

Mountable: iQuery json to table by [Guilherme Augusto Madaleno](https://github.com/guimadaleno/mountable)

Spinner: JavaScript by [Pace](https://github.hubspot.com/pace/docs/welcome/)

PuppetForge module: [os_patching](https://forge.puppet.com/albatrossflavour/os_patching)

## Limitations

Supports Ubuntu 16.04, 18.04 and CentOS 7
