# == Class: patching_status
#
# configure a web page to display system patches
# provided with the puppet module: albatrossflavour/os_patching
#
# === Parameters & Variables
#
# [*web_base*] <Stdlib::Absolutepath>
#   default: undef (This is the path that will be accessed
#            by your webserver to display the page)
#
# [*python_base*] <Stdlib::Absolutepath>
#   default: undef (This is the python virtualenv path)
#
# [*user*] <String>
#   default: root (username to assign the files to)
#
# [*group*] <String>
#   default: root (group to assign the files to)
#
# [*cron_hour*] <String>
#   default: '*' (every hour)
#
# [*cron_minute*] <String>
#   default: fqdn_rand() (once in 1 hour)
#
# [*install_method*] <Enum['ensure_packages', 'package']>
#   default: ensure_packages (to avoid conflicts with your actual configuration
#            you can change to packages method)
#
# === Credits
#
# Mountable: jQuery module to create a table from a json
#       author Guilherme Augusto Madaleno <guimadaleno@me.com>
#
# Spinner: Web Page spinnger https://github.hubspot.com/pace/docs/welcome/
#
class patching_status (
  Variant[Stdlib::IP::Address::Nosubnet, String] $puppetdb,
  Stdlib::Absolutepath $web_base,
  Stdlib::Absolutepath $python_base,
  Integer $puppetdb_port = $patching_status::params::puppetdb_port,
  String $user = $patching_status::params::user,
  String $group = $patching_status::params::group,
  Variant[String, Integer] $cron_hour = $patching_status::params::cron_hour,
  Variant[String, Integer] $cron_minute = $patching_status::params::cron_minute,
  Enum['ensure_packages', 'package'] $install_method = $patching_status::params::install_method,
) inherits patching_status::params {

  # sanity checks
  if $facts['os']['family'] == 'RedHat' {
    if $facts['lsbdistrelease'] == '6' {
      fail('CentOS/RedHat 6 are not supported')
    }
  }
  elsif $facts['os']['name'] == 'Ubuntu' {
    # we're good 
  } else {
    fail("${facts['os']['family']} ${facts['lsbdistrelease']} is not supported")
  }

  # here we go:
  class {
    'patching_status::install':
      install_method => $install_method,
      destination    => $python_base,
      user           => $user,
      cron_hour      => $cron_hour,
      cron_minute    => $cron_minute;
    'patching_status::files':
      destination   => $destination,
      user          => $user,
      group         => $group,
      puppetdb      => $puppetdb,
      puppetdb_port => $puppetdb_port;
  }

}
