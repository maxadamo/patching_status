# patching_status

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup](#setup)
    * [Setting up patching_status](#setting-up-patching_status)
1. [Screenshot](#screenshot)
1. [Development](#development)
1. [Credits](#credits)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module sets up a web pages showing the patching status of your systems. First of all you need to feed PuppetDB using the scripts provided with the Puppet module [albatrossflavour/os_patching](https://forge.puppet.com/albatrossflavour/os_patching), then this module pulls the data (through a cron job) from the PuppetDB and converts it to a HTML page.

## Requirements

* Your web server of choice points to `web_base` directory
* Your systems are already sending the patching status to the PuppetDB using the module `albatrossflavour/os_patching`

## Setup

### Setting up patching_status

This example will setup the web page:

```puppet
class { 'patching_status':
  web_base    => /webserver/directory,
  script_base => /script/path,
  puppetdb    => '192.168.1.10';
}
```

Other parameters include:

* puppetdb_port (default: 8080)
* cron_hour (default: every hour)
* cron_minute (default: once in 1 hour)
* user (default: root. User to assign the files to and install the cron job)
* group (default: root. Group to assign the files to)
* package_name (default: it's guessed based on OS name, but it can be changed)

## Screenshot

![Screenshot N/A](https://wiki.geant.org/download/attachments/126981072/patching_status.png  "Patching Status")

## Development

Want to see improvements? Please help!
I am not a front-end developer and I have only glued together a bunch of jQuery scripts and JavaScripts.

## Credits

Mountable: jQuery json-to-table by [Guilherme Augusto Madaleno](https://github.com/guimadaleno/mountable)

Spinner: JavaScript by [Pace](https://github.hubspot.com/pace/docs/welcome/)

## Limitations

The package name for Python Requests is guessed only for RedHat and Debian families, but it can be customized through the paramter `package_name`, hence the module is probably compatible with any Linux flavour on earth (running python3).
