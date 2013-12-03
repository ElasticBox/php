#
# Class php::config
#
class php::config(
  $port_http            = 80,
  $port_https           = 443,
  $certificate_password = undef,
  $destination_path     = undef,
) {
  
  file { 'config_apache.sh' :
    source => 'puppet:///modules/php/config_apache.sh',
    path   => '/tmp/config_apache.sh',
    mode   => 755,
  }
  
  exec { 'config_apache' :
    command   => "/tmp/config_apache.sh ${port_http} ${port_https} \'${certificate_password}\' ${destination_path}",
    path      => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
    logoutput => true,
    require   => File['config_apache.sh'],
  }
  
  exec { 'apache_restart':
    command   => "apachectl restart",
    path      => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
    logoutput => true,
    tries     => 5,
    require   => Exec['config_apache'],
  }
}
