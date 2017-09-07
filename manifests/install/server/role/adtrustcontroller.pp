# Class to install and configure the server role ad trust controller
class easy_ipa::install::server::role::adtrustcontroller {
  
  #package
  package{$easy_ipa::package_trust_ad_role:
    name   => $easy_ipa::package_trust_ad_role,
    ensure => installed,
  }
  package{'expect':
    ensure => installed,
  }
  
  $questions ="\u0022Active Directory domain administrator\u0027s password: \u0022"
  $command = "/usr/bin/ipa trust-add  --type=ad ${easy_ipa::ad_domain_name} --admin=${easy_ipa::ad_admin_name} --password"
  
  #if server is a master you must configure the domain approbation before
  if $easy_ipa::ipa_role == 'master' {
     exec { "server_install_${easy_ipa::ipa_server_fqdn}_role_ad_trust_controller":
        command   => "/usr/sbin/ipa-adtrust-install --admin-name=${easy_ipa::admin_name} --admin-password=${easy_ipa::admin_password}  --netbios-name=${easy_ipa::ad_netbios_name} --enable-compat --unattended",
        timeout   => 0,
        logoutput => 'on_failure',
        provider  => 'shell',
        unless    => "/usr/bin/kinit -t /etc/krb5.keytab;/usr/bin/ipa trustconfig-show | grep -wqF ${easy_ipa::ipa_server_fqdn}",
      }
      -> exec { "server_install_${easy_ipa::ipa_server_fqdn}_connection_to_AD":
        command   => "/usr/bin/echo '#!/usr/bin/expect -f \n spawn ${command} \n expect \u0022Active Directory domain administrator\u0027s password: \u0022 \n' > /tmp/reg_ad.sh;/usr/bin/chmod 755 /tmp/reg_ad.sh;",
        timeout   => 0,
        require   => Package['expect'],
        logoutput => 'on_failure',
        provider  => 'shell',
      }     
    
  } elsif $easy_ipa::ipa_role == 'replica' {
      exec { "server_install_${easy_ipa::ipa_server_fqdn}_role_ad_trust_controller":
        command   => "/usr/sbin/ipa-adtrust-install --admin-name=${easy_ipa::admin_name} --admin-password=${easy_ipa::admin_password} --netbios-name=${easy_ipa::ad_netbios_name} --enable-compat --unattended",
        timeout   => 0,
        logoutput => 'on_failure',
        provider  => 'shell',
        onlyif    => "/usr/bin/ipa trustconfig-show | grep -wqF shell_escape(${easy_ipa::ipa_server_fqdn})",
      }  
  }
}