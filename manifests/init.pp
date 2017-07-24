# == Class: ipa
#
# Manages IPA masters, replicas and clients.
#
# Parameters
# ----------
# `domain`
#      (string) The name of the IPA domain to create or join.
# `ipa_role`
#      (string) What role the node will be. Options are 'master', 'replica', and 'client'.
#
# `admin_password`
#      (string) Password which will be assigned to the IPA account named 'admin'.
#
# `directory_services_password`
#      (string) Password which will be passed into the ipa setup's parameter named "--ds-password".
#
# `autofs_package_name`
#      (string) Name of the autofs package to install if enabled.
#
# `client_install_ldaputils`
#      (boolean) If true, then the ldaputils packages are installed if ipa_role is set to client.
#
# `configure_dns_server`
#      (boolean) If true, then the parameter '--setup-dns' is passed to the IPA server installer.
#                Also, triggers the install of the required dns server packages.
#
# `configure_ntp`
#      (boolean) If false, then the parameter '--no-ntp' is passed to the IPA server installer.
#
# `custom_dns_forwarders`
#      (array[string]) Each element in this array is prefixed with '--forwarder '
#                      and passed to the IPA server installer.
#
# `domain_join_principal`
#      (string) The principal (usually username) used to join a client or replica to the IPA domain.
#
# `domain_join_password`
#      (string) The password for the domain_join_principal.
#
# `enable_hostname`
#      (boolean) If true, then the parameter '--hostname' is populated with the parameter 'ipa_server_fqdn'
#                and passed to the IPA installer.
#
# `enable_ip_address`
#      (boolean) If true, then the parameter '--ip-address' is populated with the parameter 'ip_address'
#                and passed to the IPA installer.
#
# `fixed_primary`
#      (boolean) If true, then the parameter '--fixed-primary' is passed to the IPA installer.
#
# `idstart`
#      (integer) From the IPA man pages: "The starting user and group id number".
#
# `install_autofs`
#      (boolean) If true, then the autofs packages are installed.
#
# `install_epel`
#      (boolean) If true, then the epel repo is installed. The epel repo is usually required for sssd packages.
#
# `install_kstart`
#      (boolean) If true, then the kstart packages are installed.
#
# `install_sssdtools`
#      (boolean) If true, then the sssdtools packages are installed.
#
# `ipa_client_package_name`
#      (string) Name of the IPA client package.
#
# `ipa_server_package_name`
#      (string) Name of the IPA server package.
#
# `install_ipa_client`
#      (boolean) If true, then the IPA client packages are installed if the parameter 'ipa_role' is set to 'client'.
#
# `install_ipa_server`
#      (boolean) If true, then the IPA server packages are installed if the parameter 'ipa_role' is not set to 'client'.
#
# `install_sssd`
#      (boolean) If true, then the sssd packages are installed.
#
# `ip_address`
#      (string) IP address to pass to the IPA installer.
#
# `ipa_server_fqdn`
#      (string) Actual fqdn of the IPA server or client.
#
# `kstart_package_name`
#      (string) Name of the kstart package.
#
# `ldaputils_package_name`
#      (string) Name of the ldaputils package.
#
# `ipa_master_fqdn`
#      (string) FQDN of the server to use for a client or replica domain join.
#
# `manage_host_entry`
#      (boolean) If true, then a host entry is created using the parameters 'ipa_server_fqdn' and 'ip_address'.
#
# `mkhomedir`
#      (boolean) If true, then the parameter '--mkhomedir' is passed to the IPA client installer.
#
# `no_ui_redirect`
#      (boolean) If true, then the parameter '--no-ui-redirect' is passed to the IPA server installer.
#
# `realm`
#      (string) The name of the IPA realm to create or join.
#
# `server_install_ldaputils`
#      (boolean) If true, then the ldaputils packages are installed if ipa_role is not set to client.
#
# `sssd_package_name`
#      (string) Name of the sssd package.
#
# `sssdtools_package_name`
#      (string) Name of the sssdtools package.
#
# `webui_disable_kerberos`
#      (boolean) If true, then /etc/httpd/conf.d/ipa.conf is written to exclude kerberos support for
#                incoming requests whose HTTP_HOST variable match the parameter 'webio_proxy_external_fqdn'.
#                This allows the IPA Web UI to work on a proxied port, while allowing IPA client access to
#                function as normal.
#
# `webui_enable_proxy`
#      (boolean) If true, then httpd is configured to act as a reverse proxy for the IPA Web UI. This allows
#                for the Web UI to be accessed from different ports and hostnames than the default.
#
# `webui_force_https`
#      (boolean) If true, then /etc/httpd/conf.d/ipa-rewrite.conf is modified to force all connections to https.
#                This is necessary to allow the WebUI to be accessed behind a reverse proxy when using nonstandard
#                ports.
#
# `webui_proxy_external_fqdn`
#      (string) The public or external FQDN used to access the IPA Web UI behind the reverse proxy.
#
# `webui_proxy_https_port`
#      (integer) The HTTPS port to use for the reverse proxy. Cannot be 443.
#
# TODO: Allow creation of root zone for isolated networks -- https://www.freeipa.org/page/Howto/DNS_in_isolated_networks
# TODO: Class comments.
# TODO: Dependencies and metadata updates.
# TODO: Variable scope and passing.
# TODO: Params.pp.
# TODO: configurable admin username.
#
class easy_ipa (
  String        $domain,
  String        $ipa_role,
  String        $admin_password                     = '',
  String        $directory_services_password        = '',
  String        $autofs_package_name                = 'autofs',
  Boolean       $client_install_ldaputils           = false,
  Boolean       $configure_dns_server               = true,
  Boolean       $configure_ntp                      = true,
  Array[String] $custom_dns_forwarders              = [],
  String        $domain_join_principal              = '',
  String        $domain_join_password               = '',
  Boolean       $enable_hostname                    = true,
  Boolean       $enable_ip_address                  = false,
  Boolean       $fixed_primary                      = false,
  Integer       $idstart                            = (fqdn_rand('10737') + 10000),
  Boolean       $install_autofs                     = false,
  Boolean       $install_epel                       = true,
  Boolean       $install_kstart                     = true,
  Boolean       $install_sssdtools                  = true,
  String        $ipa_client_package_name            = $::osfamily ? {
    'Debian' => 'freeipa-client',
    default  => 'ipa-client',
  },
  String        $ipa_server_package_name            = 'ipa-server',
  Boolean       $install_ipa_client                 = true,
  Boolean       $install_ipa_server                 = true,
  Boolean       $install_sssd                       = true,
  String        $ip_address                         = '',
  String        $ipa_server_fqdn                    = $::fqdn,
  String        $kstart_package_name                = 'kstart',
  String        $ldaputils_package_name             = $::osfamily ? {
    'Debian' => 'ldap-utils',
    default  => 'openldap-clients',
  },
  String        $ipa_master_fqdn                    = '',
  Boolean       $manage_host_entry                  = false,
  Boolean       $mkhomedir                          = true,
  Boolean       $no_ui_redirect                     = false,
  String        $realm                              = '',
  Boolean       $server_install_ldaputils           = true,
  String        $sssd_package_name                  = 'sssd-common',
  String        $sssdtools_package_name             = 'sssd-tools',
  Boolean       $webui_disable_kerberos             = false,
  Boolean       $webui_enable_proxy                 = false,
  Boolean       $webui_force_https                  = false,
  String        $webui_proxy_external_fqdn          = 'localhost',
  String        $webui_proxy_https_port             = '8440',
) {

  if $facts['kernel'] != 'Linux' or $facts['osfamily'] == 'Windows' {
    fail('This module is only supported on Linux.')
  }

  if $realm != '' {
    $final_realm = $realm
  } else {
    $final_realm = upcase($domain)
  }

  $master_principals = suffix(
    prefix(
      [$ipa_server_fqdn],
      'host/'
    ),
    "@${final_realm}"
  )

  if $domain_join_principal != '' {
    $final_domain_join_principal = $domain_join_principal
  } else {
    $final_domain_join_principal = 'admin'
  }

  if $domain_join_password != '' {
    $final_domain_join_password = $domain_join_password
  } else {
    $final_domain_join_password = $directory_services_password
  }

  if $ipa_role == 'client' {
    $final_configure_dns_server = false
  } else {
    $final_configure_dns_server = $configure_dns_server
  }

  class {'::easy_ipa::validate_params':}
  -> class {'::easy_ipa::install':}

}
