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
# [*python3_requests_package_name*] <String>
#   default: <os based> (the name of the package for Python3 Requests)
#
# [*ssl_enabled*] <Boolean>
#   default: <undef> (set to true if you want to enable SSL)
#
# [*ssl_cert*] <String>
#   default: <undef> (SSL certificate content)
#
# [*ca_cert*] <String>
#   default: <undef> (CA certificate content)
#
# [*ssl_key*] <Sensitive>
#   default: <undef> (SSL key content)
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
  Integer $puppetdb_port                       = 8080,
  String $user                                 = 'root',
  String $group                                = 'root',
  Variant[String, Array, Integer] $cron_hour   = '*',
  Variant[String, Array, Integer] $cron_minute = fqdn_rand(60, $module_name),
  String $python3_requests_package_name        = $facts['os']['family'] ? {
    'Archlinux' => 'python-requests',
    'Debian'    => 'python3-requests',
    'RedHat'    => 'python36-requests',
  },
  Optional[Boolea] $ssl_enabled                = undef,
  Optional[String] $ssl_cert                   = undef,  # ssl_cert content
  Optional[String] $ca_cert                    = undef,  # ca_cert content
  Optional[Sensitive] $ssl_key                 = undef,  # ssl_key content
) {

  # every Linux is supported. We only need to install python3 requests
  unless $facts['kernel'] == 'Linux' {
    fail("${facts['kernel']} is not supported")
  }

  unless defined(Package[$python3_requests_package_name]) {
    package { $python3_requests_package_name: ensure => installed; }
  }

  if ($ssl_enabled) {
    if ($ssl_cert) and ($ca_cert) and ($ssl_key) {
      file {
        default:
          require => Exec["install_${script_base}_base"],
          owner   => $user,
          group   => $group;
        "${script_base}/puppet_db/certs":
          ensure => directory;
        "${script_base}/puppet_db/cert.crt":
          content => $ssl_cert;
        "${script_base}/puppet_db/ca_cert.crt":
          content => $ca_cert;
        "${script_base}/puppet_db/cert.key":
          content => Sensitive($ssl_key.unwrap);
      }
    } else {
      fail('ssl_enabled requires to set ssl_cert, ca_cert and ssl_key')
    }
  }

  cron { 'patching_status':
    ensure  => present,
    user    => $user,
    command => "${script_base}/puppetdb_json.py",
    hour    => $cron_hour,
    minute  => $cron_minute;
  }

  # let's use "install" as puppet could not easily create the full paths
  [$script_base, $web_base].each | $base_dir | {
    exec { "install_${base_dir}_base":
      command => "install -o ${user} -g ${group} -d ${base_dir}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      creates => $base_dir;
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
      source  => "puppet:///modules/${module_name}";
    "${script_base}/puppetdb_json.py":
      mode    => '0755',
      content => epp("${module_name}/puppetdb_json.py.epp", { script_base => $script_base });
    "${script_base}/.patching_status.conf":
      content => epp("${module_name}/patching_status.conf.epp", {
        script_base   => $script_base,
        web_base      => $web_base,
        puppetdb      => $puppetdb,
        puppetdb_port => $puppetdb_port,
      });
    "${web_base}/index.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_updates' });
    "${web_base}/index_sec_updates.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_sec_updates' });
    "${web_base}/index_reboot.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_reboot' });
    "${web_base}/index_certname.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_certname' });
    "${web_base}/index_os_release.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_os_release' });
    "${web_base}/index_lsbdistdescription.html":
      ensure => absent;
  }

}
