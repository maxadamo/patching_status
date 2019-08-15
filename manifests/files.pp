# == Class: patching_status::files
#
#
class patching_status::files (
  $python_base,
  $web_base,
  $user,
  $group,
  $puppetdb,
  $puppetdb_port
) {

  file {
    default:
      ensure  => present,
      owner   => $user,
      group   => $group,
      require => Exec['create_patching_status_venv'];
    $web_base:
      ensure  => directory,
      recurse => true,
      source  => "puppet:///modules/${module_name}/patching";
    "${python_base}/patching_venv/bin/puppetdb_json.py":
      mode    => '0755',
      content => epp("${module_name}/puppetdb_json.py.epp", { python_base => $python_base });
    "${python_base}/.patching_status.conf":
      content => epp("${module_name}/patching_status.conf.epp", {
        web_base      => $web_base,
        puppetdb      => $puppetdb,
        puppetdb_port => $puppetdb_port,
      });
    "${python_base}/index.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_updates' });
    "${python_base}//index_sec_updates.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_sec_updates' });
    "${python_base}/index_reboot.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_reboot' });
    "${python_base}/index_certname.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_certname' });
    "${python_base}/index_lsbdistdescription.html":
      content => epp("${module_name}/index.html.epp", { json_file => 'puppetdb_lsbdistdescription' });
  }

}
