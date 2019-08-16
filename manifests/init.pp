# == Class: patching_status
#
# configure a web page to display the patching status 
# provided with the puppet module: albatrossflavour/os_patching
#
# === Parameters & Variables
#
# [*web_base*] <Stdlib::Absolutepath>
#   default: not set (This is the path that will be accessed
#            by your webserver to display the page)
#
# [*script_base*] <Stdlib::Absolutepath>
#   default: not set (This is the python virtualenv path)
#
# [*puppetdb*] <IP, String>
#   default: not set (puppetDB IP or FQDN)
#
# [*puppetdb_port*] <Integer>
#   default: 8080 (puppetDB TCP port)
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
# [*package_name*] <String>
#   default: <os based> (the name of the package for Python Requests)
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
  Stdlib::Absolutepath $script_base,
  Integer $puppetdb_port = 8080,
  String $user = 'root',
  String $group = 'root',
  Variant[String, Array, Integer] $cron_hour = '*',
  Variant[String, Array, Integer] $cron_minute = fqdn_rand(60, $module_name),
  String $package_name = $facts['os']['family'] ? {
    'RedHat' => 'python36-requests',
    'Debian' => 'python3-requests'
  }
) {

  # every Linux is supported. We only need to install python3 requests
  # whose name can be customized through the paramter: package_name
  unless $facts['kernel'] == 'Linux' {
    fail("${facts['kernel']} is not supported")
  }

  unless defined(Package[$package_name]) {
    package { $package_name: ensure => installed; }
  }

  cron { 'patching_status':
    ensure  => present,
    user    => $user,
    command => "${script_base}/puppetdb_json.py",
    hour    => $cron_hour,
    minute  => $cron_minute;
  }

  # let's use "install" as puppet could not create the full paths
  [$script_base, $web_base].each | $base_dir | {
    exec { "install_${base_dir}_base":
      command => "install -o ${user} -g ${group} -d ${base_dir}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      unless  => "test -d ${base_dir}";
    }
  }

  file {
    default:
      ensure  => present,
      owner   => $user,
      group   => $group,
      require => Exec["install_${web_base}_base", "install_${script_base}_base"];
    $web_base:
      ensure  => directory,
      recurse => true,
      source  => "puppet:///modules/${module_name}/patching";
    "${script_base}/puppetdb_json.py":
      mode    => '0755',
      content => epp("${module_name}/patching/puppetdb_json.py.epp", { script_base => $script_base });
    "${script_base}/.patching_status.conf":
      content => epp("${module_name}/patching/patching_status.conf.epp", {
        web_base      => $web_base,
        puppetdb      => $puppetdb,
        puppetdb_port => $puppetdb_port,
      });
    "${web_base}/index.html":
      content => epp("${module_name}/patching/index.html.epp", { json_file => 'puppetdb_updates' });
    "${web_base}/index_sec_updates.html":
      content => epp("${module_name}/patching/index.html.epp", { json_file => 'puppetdb_sec_updates' });
    "${web_base}/index_reboot.html":
      content => epp("${module_name}/patching/index.html.epp", { json_file => 'puppetdb_reboot' });
    "${web_base}/index_certname.html":
      content => epp("${module_name}/patching/index.html.epp", { json_file => 'puppetdb_certname' });
    "${web_base}/index_lsbdistdescription.html":
      content => epp("${module_name}/patching/index.html.epp", { json_file => 'puppetdb_lsbdistdescription' });
  }

}
