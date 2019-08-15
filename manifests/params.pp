# == Class: patching_status::params
#
#
class patching_status::params {

  $user = 'root'
  $group ='root'
  $install_method = 'ensure_packages'

  $packages_list = $facts['os']['name'] ? {
    'Ubuntu' => ['python3-virtualenv', 'python36-pip'],
    default  => ['python36-virtualenv', 'python36-pip']
  }

  $cron_minute = fqdn_rand(60, $module_name)
  $cron_hour = '*'

  $puppetdb_port = 8080

}
