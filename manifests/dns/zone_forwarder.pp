#
define easy_ipa::dns::zone_forwarder (
  Array[String] $forwarder_addresses,
  String        $ensure             = 'present',
  String        $zone_name          = $title,
  String        $forward_policy     = 'first',
  Boolean       $skip_overlap_check = false,
  String        $principal          = 'admin',
){
  if $ensure != 'present' {
    fail('The only supported option for the parameter named ensure is \'present\'.')
  }

  # TODO: forward_policy in 'first', 'none', 'only'

  if $skip_overlap_check {
    $cmd_skip_overlap_check = '--skip-overlap-check'
  } else {
    $cmd_skip_overlap_check = ''
  }
  $cmd_forward_policy = "--forward-policy=${forward_policy}"

  $forwarder_addresses_x = map($forwarder_addresses) |$parameter| {
    "--forwarder ${parameter}"  # lint:ignore:variable_scope
  }
  $forwarder_addresses_joined = join($forwarder_addresses_x, ' ')

  # Create the zone
  $cmd_create_forward_zone = "\
su ${principal} -c '\
  ipa dnsforwardzone-add ${zone_name}\
  ${cmd_skip_overlap_check}\
  ${cmd_forward_policy}\
  ${forwarder_addresses_joined}\
'"

  $cmd_create_forward_zone_unless = "\
su ${principal} -c '\
  ipa dnsforwardzone-find --name=${zone_name}\
'"

  exec{"forwarder_zone_${zone_name}":
    command  => $cmd_create_forward_zone,
    unless   => $cmd_create_forward_zone_unless,
    provider => 'shell',
    before   => [
      Exec["forwarder_zone_${zone_name}_forward_policy"],
      Exec["forwarder_zone_${zone_name}_forwarders"],
    ]
  }

  # Change forward policy
  $cmd_mod_forward_policy = "\
su ${principal} -c '\
  ipa dnsforwardzone-mod ${zone_name}\
  --forward-policy=${forward_policy}\
'"

  $cmd_mod_forward_policy_unless = "\
su ${principal} -c '\
  ipa dnsforwardzone-find --name=${zone_name}\
  | grep Forward\\ policy | grep -i ${forward_policy}\
'"

  exec{"forwarder_zone_${zone_name}_forward_policy":
    command  => $cmd_mod_forward_policy,
    unless   => $cmd_mod_forward_policy_unless,
    provider => 'shell',
  }

  # Change forwarders
  $cmd_mod_forwarders = "\
su ${principal} -c '\
  ipa dnsforwardzone-mod ${zone_name}\
  ${forwarder_addresses_joined}\
'"

  $forwarder_addresses_grep_x = map($forwarder_addresses) |$parameter| {
    " | grep ${parameter}"  # lint:ignore:variable_scope
  }
  $forwarder_addresses_grep_joined = join($forwarder_addresses_grep_x, ' ')

  $cmd_mod_forwarders_unless = "\
su ${principal} -c '\
  ipa dnsforwardzone-find ${zone_name}\
  ${forwarder_addresses_grep_joined}\
'"

  exec{"forwarder_zone_${zone_name}_forwarders":
    command  => $cmd_mod_forwarders,
    unless   => $cmd_mod_forwarders_unless,
    provider => 'shell',
  }

}
