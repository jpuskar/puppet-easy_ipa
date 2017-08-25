# Class to install and configure the server role CA
class easy_ipa::install::server::role::ca {
  #if server is a master nothing to do
  if $easy_ipa::ipa_role == 'replica' {
     exec { "server_install_${easy_ipa::ipa_server_fqdn}_role_ca":
        command   => "/usr/sbin/ipa-ca-install  --password=${easy_ipa::directory_services_password}",
        timeout   => 0,
        logoutput => 'on_failure',
        feature   => 'shell',
        onlyif    => "/usr/bin/ipa server-find --servrole='CA server' --name ${easy_ipa::ipa_server_fqdn} | grep -wq 0",
     }
  } 
}