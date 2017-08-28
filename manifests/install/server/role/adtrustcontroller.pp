# Class to install and configure the server role ad trust controller
class easy_ipa::install::server::role::adtrustcontroller {
  
  #package
  package{$easy_ipa::package_trust_ad_role:
    name   => $easy_ipa::package_trust_ad_role,
    ensure => present,
  }
  
  #if server is a master you must configure the domain approbation before
  if $easy_ipa::ipa_role == 'master' {
     exec { "server_install_${easy_ipa::ipa_server_fqdn}_role_ad_trust_controller":
        command   => "/usr/sbin/ipa-adtrust-install  --netbios-name=${easy_ipa::ad_netbios_name} --enable-compat",
        timeout   => 0,
        logoutput => 'on_failure',
        provider  => 'shell',
        onlyif    => "/usr/bin/ipa server-find --servrole='AD Trust controller' --name ${easy_ipa::ipa_server_fqdn} | grep -wq 0",
      }
      -> exec { "server_install_${easy_ipa::ipa_server_fqdn}_connection_to_AD":
        command   => "/usr/bin/ipa trust-add  --type= ad ${easy_ipa::ad_domain_name} --admin=${easy_ipa::ad_admin_name} --password=${easy_ipa::ad_admin_password}",
        timeout   => 0,
        logoutput => 'on_failure',
      }     
    
  } elsif $easy_ipa::ipa_role == 'replica' {
      exec { "server_install_${easy_ipa::ipa_server_fqdn}_role_ad_trust_controller":
        command   => "/usr/sbin/ipa-adtrust-install  --netbios-name=${easy_ipa::ad_netbios_name} --enable-compat",
        timeout   => 0,
        logoutput => 'on_failure',
        provider  => 'shell',
        onlyif    => "/usr/bin/ipa server-find --servrole='AD Trust controller' --name ${easy_ipa::ipa_server_fqdn} | grep -wq 0",
      }  
  }
}