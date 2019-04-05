#
# Class php 
#
class php(
  $port_http            = 80,
  $port_https           = 443,
  $certificate_password = undef,
  $destination_path     = undef,
) {
  
  include 'php::params'
  include 'php::epel'

  Class['php'] -> Class['php::config']

  $config_hash = {
    'port_http'            => "${port_http}",
    'port_https'           => "${port_https}",
    'certificate_password' => "${certificate_password}",
    'destination_path'     => "${destination_path}",
  }

  $config_class = { 'php::config' => $config_hash }

  create_resources( 'class', $config_class )

  package { 'apache':
    ensure  => present,
    name    => $php::params::apache_package,
    require => Class['php::epel'],
  }
  
  if $certificate_password {
    if ($operatingsystem == 'Amazon') or ($osfamily == 'RedHat') {
      package { 'mod_ssl' :
        ensure  => present,
        require => Package['apache'],
      }
    } elsif ($osfamily == 'Debian') {
      exec { 'a2enmod ssl': 
        path      => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
        logoutput => true,
        require   => Package['apache'],
      }
    }
  }
  
  package { $php::params::php_packages :
    ensure  => present,
    require => Package['apache'], 
  }
  
  service { 'apache-service':
    ensure     => running,
    name       => $php::params::apache_service,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[$php::params::php_packages],
  }
}
