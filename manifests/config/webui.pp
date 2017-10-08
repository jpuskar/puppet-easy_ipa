# Configures port and redirect overrides for the IPA server web UI.
class easy_ipa::config::webui {

  if $easy_ipa::webui_enable_proxy {
    #ref: https://www.redhat.com/archives/freeipa-users/2016-June/msg00128.html
    $proxy_server_internal_fqdn = $easy_ipa::ipa_server_fqdn
    $proxy_server_external_fqdn = $easy_ipa::webui_proxy_external_fqdn
    $proxy_https_port = $easy_ipa::webui_proxy_https_port

    $proxy_server_external_fqdn_and_port = "${proxy_server_external_fqdn}:${proxy_https_port}"

    $proxy_internal_uri = "https://${proxy_server_internal_fqdn}"
    $proxy_external_uri = "https://${proxy_server_external_fqdn}:${proxy_https_port}"
    $proxy_server_name = "https://${easy_ipa::ipa_server_fqdn}:${proxy_https_port}"
    $proxy_referrer_regex = regsubst(
      $proxy_external_uri,
      '\.',
      '\.',
      'G',
    )

    file_line { 'webui_additional_https_port_listener':
      ensure => present,
      path   => '/etc/httpd/conf.d/nss.conf',
      line   => "Listen ${proxy_https_port}",
      after  => 'Listen\ 443',
      notify => Service['httpd'],
    }

    file { '/etc/httpd/conf.d/ipa-rewrite.conf':
      ensure  => present,
      replace => true,
      content => template('easy_ipa/ipa-rewrite.conf.erb'),
      notify  => Service['httpd'],
    }

    file { '/etc/httpd/conf.d/ipa-webui-proxy.conf':
      ensure  => present,
      replace => true,
      content => template('easy_ipa/ipa-webui-proxy.conf.erb'),
      notify  => Service['httpd'],
    }
  }

  if $easy_ipa::webui_disable_kerberos {

    $onlyif_disable_ipa_webui_kerberos = @(END_ONLYIF_DISABLE_IPA_WEBUI_KERBEROS)
      set -eou pipefail;
      RES=$(/opt/puppetlabs/puppet/bin/augtool << EOF
      defvar cf '/files/etc/httpd/conf.d/ipa.conf'
      defvar cf_ipa "\$cf/Location[arg='\"/ipa\"']"
      print \$cf_ipa/If
      EOF
      );
      echo $RES | grep HTTP_HOST;
      | END_ONLYIF_DISABLE_IPA_WEBUI_KERBEROS

    $cmd_disable_ipa_webui_kerberos = @(END_CMD_DISABLE_IPA_WEBUI_KERBEROS)
      /opt/puppetlabs/puppet/bin/augtool -b << EOF
      defvar cf '/files/etc/httpd/conf.d/ipa.conf'
      defvar cf_ipa "\$cf/Location[arg='\"/ipa\"']"
      cp \$cf_ipa \$cf/If
      mv \$cf/If \$cf_ipa/If
      set \$cf_ipa/If/arg "\"%{HTTP_HOST} != 'localhost:8440'\""
      rm \$cf_ipa/*[self::directive =~ regexp("^Gss.*")]
      rm \$cf_ipa/*[self::directive =~ regexp("^Auth.*")]
      rm \$cf_ipa/*[self::directive =~ regexp("^Require.*")]
      save
      EOF
      | END_CMD_DISABLE_IPA_WEBUI_KERBEROS

    exec { 'disable_ipa_webui_kerberos':
      command  => $cmd_disable_ipa_webui_kerberos,
      unless   => $onlyif_disable_ipa_webui_kerberos,
      provider => 'shell',
      notify   => Service['httpd'],
    }

  }
}
