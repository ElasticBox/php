#
# Class php::params
#
class php::params {

  case $::operatingsystem {
    /(Amazon|CentOS|Fedora|RedHat)/: {
      $apache_package     = 'httpd'
      $apache_service     = 'httpd'
      $apache_config_file = 'httpd.conf'
      $apache_config_path = '/etc/httpd/conf.d'
      $php_packages       = [ 'php', 'php-devel', 'php-gd', 
                              'php-imap', 'php-ldap', 'php-mysql', 
                              'php-odbc', 'php-pear', 'php-xml', 
                              'php-xmlrpc', 'curl', 'ImageMagick', 
                              'libxml2', 'libxml2-devel' ]
    }
    /(Debian|Ubuntu)/: {
      $apache_package     = 'apache2'
      $apache_service     = 'apache2'
      $apache_config_file = 'apache2.conf'
      $apache_config_path = '/etc/apache2'
      $php_packages       = [ 'php5', 'php5-mysql', 'php5-curl', 
                              'php5-gd', 'php5-idn', 'php-pear',
                              'php5-imagick', 'php5-imap', 
                              'php5-mcrypt','php5-memcache',
                              'php5-mhash', 'php5-ming', 'php5-ps', 
                              'php5-pspell', 'php5-recode',
                              'php5-snmp', 'php5-sqlite',
                              'php5-tidy', 'php5-xmlrpc','php5-xsl', 
                              'php5-json', 'libapache2-mod-php5' ]
    }
    default: {
      fail('Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}')
    }
  }
}
