# == Class: patching_status::files
#
#
class patching_status::files (
  $destination,
  $user,
  $group,
  $puppetdb,
  $puppetdb_port
) {

  file {
    default:
      ensure  => present,
      mode    => '0755',
      owner   => $user,
      group   => $group,
      require => Exec['create_patching_status_venv'];
    $destination:
      ensure => directory,
      source => "puppet:///modules/${module_name}/patching";
    "${destination}/patching_venv/bin/puppetdb_json.py":
      source => "puppet:///modules/${module_name}/puppetdb_json.py";
    "${destination}/.patching_status.conf":
      content => epp("${module_name}/patching_status.conf.epp", {
        destination   => $destination,
        puppetdb      => $puppetdb,
        puppetdb_port => $puppetdb_port,
      });
    '/var/repositories/patching/index.html':
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_updates' });
    '/var/repositories/patching/index_sec_updates.html':
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_sec_updates' });
    '/var/repositories/patching/index_reboot.html':
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_reboot' });
    '/var/repositories/patching/index_certname.html':
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_certname' });
    '/var/repositories/patching/index_lsbdistdescription.html':
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_lsbdistdescription' });
  }

}
