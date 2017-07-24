#
class easy_ipa::install::sssd {

  package { $easy_ipa::sssd_package_name:
    ensure => present,
  }

}