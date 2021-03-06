# patching_status

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup](#setup)
    * [Setting up patching_status](#setting-up-patching_status)
    * [Enabling SSL](#enabling-ssl)
1. [Screenshot](#screenshot)
1. [Development](#development)
1. [Credits](#credits)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module sets up a web page showing the patching status of your systems. First of all you need to feed PuppetDB using the scripts provided with the Puppet module [albatrossflavour/os_patching](https://forge.puppet.com/albatrossflavour/os_patching), then this module pulls the data (through a cron job) from the PuppetDB and converts it to a HTML page.

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
* python3_requests_package_name (default: it's guessed based on OS family.)
* ssl_enabled (default: undef. It can be set to `true` if your puppetDB has SSL)
* ssl_cert (default: undef. PuppetDB certificate content)
* ca_cer (default: undef. PuppetDB CA certificate content)
* ssl_key (default: undef. PuppetDB certificate key content. It requires Sensitive datatype)

### Enabling SSL

The example below connects to PuppetDB using SSL (you probably want to store the certificates in hiera and use variables instead). Sensitive datatype is mandatory for the key:

```puppet
class { 'patching_status':
  web_base    => /webserver/directory,
  script_base => /script/path,
  puppetdb    => '192.168.1.10',
  ssl_enabled => true,
  ssl_cert    => "-----BEGIN CERTIFICATE-----\nMIIF.....", # you may use a variable here
  ca_cert     => "-----BEGIN CERTIFICATE-----\nMIIF.....", # you may use a variable here
  ssl_key     => Sensitive("-----BEGIN CERTIFICATE-----\nMIIF....."); # you may use a variable here
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

The package name for Python Requests is guessed only for RedHat, Debian, Archlinux families, but it can be customized through the paramter `python3_requests_package_name`, hence the module is probably compatible with any Linux flavour on earth (running python3).
