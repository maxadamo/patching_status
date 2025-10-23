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
# [*puppetdb_port*] <Stdlib::Port>
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
#   default: <undef> (SSL certificate content from hiera)
#
# [*ca_cert*] <String>
#   default: <undef> (CA certificate content from hiera)
#
# [*ssl_key*] <Sensitive>
#   default: <undef> (SSL key content from hiera)
#
# [*ssl_cert_path*] <Stdlib::Absolutepath>
#   default: <undef> (File-system path for local SSL certificate)
#
# [*ca_cert_path*] <Stdlib::Absolutepath>
#   default: <undef> (File-system path for local CA certificate)
#
# [*ssl_key_path*] <Stdlib::Absolutepath>
#   default: <undef> (File-system path for local SSL certificate key)
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
  Stdlib::Port $puppetdb_port                   = 8080,
  String $user                                  = 'root',
  String $group                                 = 'root',
  Variant[String, Array, Integer] $cron_hour    = '*',
  Variant[String, Array, Integer] $cron_minute  = fqdn_rand(60, $module_name),
  String $python3_requests_package_name         = $facts['os']['family'] ? {
    'Archlinux' => 'python-requests',
    'Debian'    => 'python3-requests',
    'RedHat'    => 'python36-requests',
  },
  Boolean $ssl_enabled                          = false,
  Optional[String] $ssl_cert                    = undef,  # ssl_cert content
  Optional[String] $ca_cert                     = undef,  # ca_cert content
  Optional[Sensitive] $ssl_key                  = undef,  # ssl_key content
  Optional[Stdlib::Absolutepath] $ssl_cert_path = undef,  # ssl_cert file path
  Optional[Stdlib::Absolutepath] $ca_cert_path  = undef,  # ca_cert file path
  Optional[Stdlib::Absolutepath] $ssl_key_path  = undef,  # ssl_key file path
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
      $puppetdb_certs_dir = "${script_base}/puppetdb_certs"
      $ssl_cert_file = "${puppetdb_certs_dir}/cert.crt"
      $ca_cert_file = "${puppetdb_certs_dir}/ca_cert.crt"
      $ssl_key_file = "${puppetdb_certs_dir}/cert.key"
      file {
        default:
          require => Exec["install_${script_base}_base"],
          owner   => $user,
          group   => $group;
        $puppetdb_certs_dir:
          ensure => directory,
          before => File[
            $ssl_cert_file,
            $ca_cert_file,
            $ssl_key_file,
          ];
        $ssl_cert_file:
          content => $ssl_cert;
        $ca_cert_file:
          content => $ca_cert;
        $ssl_key_file:
          mode    => '0640',
          content => Sensitive($ssl_key.unwrap);
      }
    } elsif ($ssl_cert_path) and ($ca_cert_path) and ($ssl_key_path) {
      $ssl_cert_file = $ssl_cert_path
      $ca_cert_file = $ca_cert_path
      $ssl_key_file = $ssl_key_path
    } else {
      fail('ssl_enabled requires certificate content or filesystem paths to be set')
    }
  } else {
    $ssl_cert_file = undef
    $ca_cert_file = undef
    $ssl_key_file = undef
  }

  cron { 'patching_status':
    ensure  => present,
    user    => $user,
    command => "${script_base}/puppetdb_json.py",
    hour    => $cron_hour,
    minute  => $cron_minute;
  }

  # let's use "install" as puppet could not create the full paths with ease
  [$script_base, $web_base].each | $base_dir | {
    exec { "install_${base_dir}_base":
      command => "install -o ${user} -g ${group} -d ${base_dir}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      creates => $base_dir;
    }
  }

  file {
    default:
      owner   => $user,
      group   => $group,
      require => Exec["install_${web_base}_base", "install_${script_base}_base"];
    $web_base:
      ensure  => directory,
      recurse => true,
      source  => "puppet:///modules/${module_name}";
    "${script_base}/puppetdb_json.py":
      mode   => '0755',
      source => "puppet:///modules/${module_name}/puppetdb_json.py";
    "${script_base}/.patching_status.conf":
      content => epp("${module_name}/patching_status.conf.epp",
        {
          ssl_enabled   => $ssl_enabled,
          ssl_cert_file => $ssl_cert_file,
          ca_cert_file  => $ca_cert_file,
          ssl_key_file  => $ssl_key_file,
          web_base      => $web_base,
          puppetdb      => $puppetdb,
          puppetdb_port => $puppetdb_port,
        }
      );
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
  }
}
