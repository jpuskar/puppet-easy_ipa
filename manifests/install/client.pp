#
class easy_ipa::install::client {

  package{$easy_ipa::ipa_client_package_name:
    ensure => present,
  }

  package{$easy_ipa::kstart_package_name:
    ensure => present,
  }

  if $easy_ipa::client_install_ldaputils {
    package { $easy_ipa::ldaputils_package_name:
      ensure => present,
    }
  }

  if $easy_ipa::mkhomedir {
    $client_install_cmd_opts_mkhomedir = '--mkhomedir'
  } else {
    $client_install_cmd_opts_mkhomedir = ''
  }

  if $easy_ipa::fixed_primary {
    $client_install_cmd_opts_fixed_primary = '--fixed-primary'
  } else {
    $client_install_cmd_opts_fixed_primary = ''
  }

  if $easy_ipa::configure_ntp {
    $client_install_cmd_opts_no_ntp = ''
  } else {
    $client_install_cmd_opts_no_ntp = '--no-ntp'
  }

    $client_install_cmd = "\
/usr/sbin/ipa-client-install \
  --server=${easy_ipa::ipa_master_fqdn} \
  --realm=${easy_ipa::final_realm} \
  --domain=${easy_ipa::domain} \
  --principal='${easy_ipa::final_domain_join_principal}' \
  --password='${easy_ipa::final_domain_join_password}' \
  ${client_install_cmd_opts_mkhomedir} \
  ${client_install_cmd_opts_fixed_primary} \
  ${client_install_cmd_opts_no_ntp} \
  --unattended"

  exec { "client_install_${::fqdn}":
    command   => $client_install_cmd,
    timeout   => 0,
    unless    => "cat /etc/ipa/default.conf | grep -i \"${easy_ipa::domain}\"",
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    before    => Service['sssd'],
    provider  => 'shell',
  }

  if $easy_ipa::install_sssd {
    service { 'sssd':
      ensure  => 'running',
      enable  => true,
      require => Package[$easy_ipa::sssd_package_name],
    }
  }
}
