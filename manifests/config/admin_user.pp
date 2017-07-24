#
class easy_ipa::config::admin_user {

  $uid_number = $easy_ipa::idstart
  $home_dir_path = '/home/admin'

  # Ensure admin homedir and keytab files.
  file { $home_dir_path:
    ensure  => directory,
    mode    => '0700',
    owner   => $uid_number,
    group   => $uid_number,
    recurse => true,
    notify  => Exec['configure_admin_keytab'],
    require => Exec["server_install_${easy_ipa::ipa_server_fqdn}"],
  }

  file { "${home_dir_path}/.k5login":
    owner   => $uid_number,
    group   => $uid_number,
    require => File[$home_dir_path],
  }

  file { "${home_dir_path}/admin.keytab":
    owner   => $uid_number,
    group   => $uid_number,
    mode    => '0600',
    require => File[$home_dir_path],
    notify  => Exec['configure_admin_keytab'],
  }

  # Gives admin user the host/fqdn principal.
  k5login { "${home_dir_path}/.k5login":
    principals => $easy_ipa::master_principals,
    notify     => File["${home_dir_path}/.k5login"],
    require    => File[$home_dir_path]
  }

  # Set keytab for admin user.
  $configure_admin_keytab_cmd = "/usr/sbin/kadmin.local -q \"ktadd -norandkey -k ${home_dir_path}/admin.keytab admin\" "
  exec { 'configure_admin_keytab':
    command     => $configure_admin_keytab_cmd,
    cwd         => $home_dir_path,
    unless      => shellquote('/usr/bin/kvno','-k',"${home_dir_path}/admin.keytab","admin@${easy_ipa::final_realm}"),
    notify      => Exec['chown_admin_keytab'],
    refreshonly => true,
    require     => Cron['k5start_admin'],
  }

  $chown_admin_keytab_cmd = "chown ${uid_number}:${uid_number} ${home_dir_path}/admin.keytab"
  $chown_admin_keytab_cmd_unless = "ls -lan ${home_dir_path}/admin.keytab | grep ${uid_number}\\ ${uid_number} "
  exec { 'chown_admin_keytab':
    command  => $chown_admin_keytab_cmd,
    cwd      => $home_dir_path,
    unless   => $chown_admin_keytab_cmd_unless,
    provider => shell,
  }

  $k5start_admin_keytab_cmd = "/sbin/runuser -l admin -c \"/usr/bin/k5start -f ${home_dir_path}/admin.keytab -U\""
  $k5start_admin_keytab_cmd_unless = "/sbin/runuser -l admin -c /usr/bin/klist | grep -i krbtgt\\/${easy_ipa::final_realm}\\@"
  exec { 'k5start_admin_keytab':
    command => $k5start_admin_keytab_cmd,
    cwd     => $home_dir_path,
    unless  => $k5start_admin_keytab_cmd_unless,
    require => [
      Cron['k5start_admin'],
      Exec['chown_admin_keytab'],
    ]
  }

  # Automatically refreshes admin keytab.
  cron { 'k5start_admin':
    command => "/usr/bin/k5start -f ${home_dir_path}/admin.keytab -U > /dev/null 2>&1",
    user    => 'admin',
    minute  => '*/1',
    notify  => Exec['chown_admin_keytab'],
    require => [
      Package[$easy_ipa::kstart_package_name],
      K5login["${home_dir_path}/.k5login"],
      File[$home_dir_path]
    ],
  }

}
