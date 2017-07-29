#
define easy_ipa::dns::reverse_zone (
  $ensure          = 'present',
  $zone_name       = $title,
  $dynamic_updates = true,
  $principal       = 'admin',
){
  if $ensure != 'present' {
    fail('The only supported option for the parameter named ensure is \'present\'.')
  }

  if $dynamic_updates {
    $cmd_new_zone_opts_dynamic_updates = '--dynamic-update=TRUE'
  } else {
    $cmd_new_zone_opts_dynamic_updates = '--dynamic-update=FALSE'
  }

  $cmd_new_zone = "\
su ${principal} -c '\
  ipa dnszone-add ${zone_name}\
  ${cmd_new_zone_opts_dynamic_updates}\
'"

  $zone_name_regex = regexpescape($zone_name)
  $cmd_new_zone_unless = "\
su ${principal} -c '\
  ipa dnszone-find | grep -i Zone\\ name:\\ ${zone_name_regex}\
'"

  exec{"reverse_zone_${zone_name_regex}":
    command  => $cmd_new_zone,
    unless   => $cmd_new_zone_unless,
    provider => 'shell',
  }

}
