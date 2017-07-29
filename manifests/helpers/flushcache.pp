#
define easy_ipa::helpers::flushcache {

  $ipa_flush_cache_cmd = @(END_IPA_FLUSH_CACHE_CMD)
    if [ -x /usr/sbin/nscd ]; then
      /usr/sbin/nscd -i passwd -i group -i netgroup -i automount >/dev/null 2>&1
    fi

    if [ -x /usr/sbin/sss_cache ]; then
      /usr/sbin/sss_cache -UGNA >/dev/null 2>&1
    else
      /usr/bin/find /var/lib/sss/db -type f -exec rm -f {}
    fi
    | END_IPA_FLUSH_CACHE_CMD

  exec { "ipa_flushcache_${title}":
    command     => "/bin/bash -c ${ipa_flush_cache_cmd}",
    returns     => ['0','1','2'],
    notify      => Service['sssd'],
    refreshonly => true,
  }

}
