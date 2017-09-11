#
class easy_ipa::install::server::master {
  $server_install_cmd = "\
/usr/sbin/ipa-server-install \
  ${easy_ipa::install::server::server_install_cmd_opts_hostname} \
  --realm=${easy_ipa::final_realm} \
  --domain=${easy_ipa::domain} \
  --admin-password='${easy_ipa::admin_password}' \
  --ds-password='${easy_ipa::directory_services_password}' \
  ${easy_ipa::install::server::server_install_cmd_opts_setup_dns} \
  ${easy_ipa::install::server::server_install_cmd_opts_forwarders} \
  ${easy_ipa::install::server::server_install_cmd_opts_ip_address} \
  ${easy_ipa::install::server::server_install_cmd_opts_no_ntp} \
  ${easy_ipa::install::server::server_install_cmd_opts_idstart} \
  ${easy_ipa::install::server::server_install_cmd_opts_no_ui_redirect} \
  --unattended"

  # update to take option install_kstart
  if $easy_ipa::install_kstart {
    $command = '/usr/bin/k5start -f /etc/krb5.keytab -U -o root -k /tmp/krb5cc_0 > /dev/null 2>&1'
  }
  else{
    $command = '/usr/bin/kinit -t /etc/krb5.keytab'
  }
  # update to use cron for kinit or k5start
  if $easy_ipa::use_cron {
    $cron = 'present'
  }
  else{
    $cron = 'absent'
  }
  
  file { '/etc/ipa/primary':
    ensure  => 'file',
    content => 'Added by IPA Puppet module. Designates primary master. Do not remove.',
  }
  -> exec { "server_install_${easy_ipa::ipa_server_fqdn}":
    command   => $server_install_cmd,
    timeout   => 0,
    unless    => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    notify    => Easy_ipa::Helpers::Flushcache["server_${easy_ipa::ipa_server_fqdn}"],
    before    => Service['sssd'],
    #unless    => "${command};/usr/bin/ipa server-find --servrole 'CA server' | grep -wqF  ${easy_ipa::ipa_server_fqdn}",
  }
  -> cron { 'k5start_root': #allows scp to replicas as root
    command => "${command}",
    user    => 'root',
    minute  => '*/1',
    ensure  => $cron,
  }
}
