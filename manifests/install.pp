# == Class: patching_status
#
#
class patching_status::install (
  $install_method,
  $destination,
  $user,
  $group,
  $cron_hour,
  $cron_minute,
  $packackges_list = $patching_status::params::packackges_list,
) inherits patching_status::params {

  if $install_method == 'ensure_package' {
    ensure_packages($packackges_list, {
      'ensure' => 'installed',
      'before' => Exec['create_patching_status_venv']
    })
  } else {
    $packackges_list.each | $package_item | {
      unless defined(Package[$package_item]) {
        package { $package_item:
          ensure => installed,
          before => Exec['create_patching_status_venv']
        }
      }
    }
  }

  exec { 'create_patching_status_venv':
    command => "python3 -m venv ${destination}/patching_venv
      source ${destination}/patching_venv/bin/activate
      pip3 install -U pip setuptools
      pip3 install requests",
    unless  => "source ${destination}/patching_venv/bin/activate
      python3 -c \"import requests\'";
  }

  file {
    default:
      ensure => present,
      mode   => '0755',
      owner  => $user,
      group  => $group;
    $destination:
      ensure  => directory,
      source  => "puppet:///modules/${module_name}/patching";
    "${destination}/patching_venv/bin/puppetdb_json.py":
      source => "puppet:///modules/${module_name}/puppetdb_json.py";
    "${destination}/.patching_status.conf":
      content => epp("${module_name}/patching_status.conf.epp", { destination => $destination });
  }

  cron { 'patching_status':
    ensure  => present,
    command => "${destination}/patching_venv/bin/puppetdb_json.py",
    hour    => $cron_hour,
    minute  => $cron_minute;
  }

}
