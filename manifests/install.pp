# == Class: patching_status::install
#
#
class patching_status::install (
  $install_method,
  $destination,
  $user,
  $cron_hour,
  $cron_minute,
  $packages_list = $patching_status::params::packages_list,
) inherits patching_status::params {

  if $install_method == 'ensure_packages' {
    ensure_packages($packages_list, {
      'ensure' => 'installed',
      'before' => Exec['create_patching_status_venv']
    })
  } else {
    $packages_list.each | $package_item | {
      unless defined(Package[$package_item]) {
        package { $package_item:
          ensure => installed,
          before => Exec['create_patching_status_venv']
        }
      }
    }
  }

  exec { 'create_patching_status_venv':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    user    => $user,
    command => "python3 -m venv ${destination}/patching_venv
      source ${destination}/patching_venv/bin/activate
      pip3 install -U pip setuptools
      pip3 install requests",
    unless  => "test -f ${destination}/patching_venv/bin/python3 &&\
      ${destination}/patching_venv/bin/python3 -c \"import requests\"";
  }

  cron { 'patching_status':
    ensure  => present,
    user    => $user,
    command => "${destination}/patching_venv/bin/puppetdb_json.py",
    hour    => $cron_hour,
    minute  => $cron_minute;
  }

}
