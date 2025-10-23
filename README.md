# patching_status

#### Table of Contents

1. [Project Status - Final Release](#project-status---final-release)
2. [Description](#description)
3. [Requirements](#requirements)
4. [Setup](#setup)
    * [Setting up patching_status](#setting-up-patching_status)
    * [Enabling SSL](#enabling-ssl)
5. [Screenshot](#screenshot)
6. [Development](#development)
7. [Credits](#credits)
8. [Limitations - OS compatibility, etc.](#limitations)

## Project Status - Final Release

:warning: This module is now in **maintenance-only** mode, and this will be the **last release** of [maxadamo/patching_status](https://forge.puppet.com/maxadamo/patching_status).  
Future development continues in a new **containerized version**, which provides improved flexibility and easier deployment.

:point_right: You can find the new container-based implementation here: [GEANT/docker-patching-status](https://codeberg.org/GEANT/docker-patching-status)

## Description

This module sets up a web page showing the patching status of your systems. First, you must use the scripts provided by the Puppet module [albatrossflavour/os_patching](https://forge.puppet.com/albatrossflavour/os_patching).  
It runs a scheduled job that pulls data from PuppetDB, which are then displayed on an HTML page.

## Requirements

* Your web server of choice pointing to `web_base` directory
* Your systems are already sending the patching status to the PuppetDB using the module [albatrossflavour/os_patching](https://forge.puppet.com/albatrossflavour/os_patching)
* If using the parameters `ssl_cert_file`, `ca_cert_file` and `ssl_key_file`, you need to use the Puppet file resource to create these files in advance.

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
* python3_requests_package_name (default: it's guessed based on OS family.)
* ssl_enabled (default: undef. It can be set to `true` if your puppetDB has SSL)
* ssl_cert (default: undef. PuppetDB certificate content)
* ca_cert (default: undef. PuppetDB CA certificate content)
* ssl_key (default: undef. PuppetDB certificate key content. It requires Sensitive datatype)
* ssl_cert_file: (default: undef. PuppetDB certificate path)
* ca_cert_file: (default: undef. PuppetDB certificate path)
* ssl_key_file: (default: undef. PuppetDB certificate path)

### Enabling SSL

The example below connects to PuppetDB using SSL (you probably want to store the certificates in hiera and use variables instead). Sensitive datatype is mandatory for the key:

```puppet
class { 'patching_status':
  web_base    => /webserver/directory,
  script_base => /script/path,
  puppetdb    => '192.168.1.10',
  ssl_enabled => true,
  ssl_cert    => "-----BEGIN CERTIFICATE-----\nMIIF.....",
  ca_cert     => "-----BEGIN CERTIFICATE-----\nMIIF.....",
  ssl_key     => Sensitive("-----BEGIN CERTIFICATE-----\nMIIF.....");
}
```

Alternatively, for Puppet Enterprise or similar setup where a client certificate can be used to connect to PuppetDB:

```puppet
class { 'patching_status':
  web_base      => /webserver/directory,
  script_base   => /script/path,
  puppetdb      => '192.168.1.10',
  ssl_enabled   => true,
  ssl_cert_file => '/etc/puppetlabs/puppet/ssl/certs/certname.pem'
  ca_cert_file  => '/etc/puppetlabs/puppet/ssl/certs/ca.pem'
  ssl_key_file  => '/etc/puppetlabs/puppet/ssl/private_keys/certname.pem'
}
```

You need to use the Puppet file resource to create `ssl_cert_file`, `ca_cert_file` and `ssl_key_file` files in advance.

In Puppet Enterprise, you will also need to add the host this class is running on to the whitelist at puppet_enterprise::profile::puppetdb::whitelisted_certnames.

## Screenshot

![Screenshot N/A](https://wiki.geant.org/download/attachments/126981072/patching_status.png  "Patching Status")

## Development

Want to see improvements? Please help!
I am not a front-end developer and I have only glued together a bunch of jQuery scripts and JavaScripts.

## Credits

Mountable: jQuery json-to-table by [Guilherme Augusto Madaleno](https://github.com/guimadaleno/mountable)

Spinner: JavaScript by [Pace](https://github.hubspot.com/pace/docs/welcome/)

## Limitations

The package name for Python Requests is guessed only for RedHat, Debian, Archlinux families, but it can be customized through the parameter `python3_requests_package_name`, hence the module is likely compatible with any Linux distribution running Python 3.
