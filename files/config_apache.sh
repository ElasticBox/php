#!/bin/bash

http=$1
https=$2
CertificatePassword=$3
CertificatePassword=${CertificatePassword//$/\\$}
DestinationPath=$4

if [ -f /etc/yum.conf ]; then
	sed -e "/DirectoryIndex/ c\ DirectoryIndex index.html index.htm index.shtml index.cgi index.php index.php3" -i  /etc/httpd/conf/httpd.conf
	sed -e "s:Listen 80:Listen $http:g" -i /etc/httpd/conf/httpd.conf
	if [ -d $DestinationPath ] ; then
	    sed -e "s:/var/www/html:$DestinationPath:g" -i /etc/httpd/conf/httpd.conf
	    sed -e "s:/var/www:$DestinationPath:g" -i /etc/httpd/conf/httpd.conf
	fi
elif [ -f /etc/debian_version ]; then
	sed -e "s:80:$http:g" -i  /etc/apache2/ports.conf	
	sed -e "s:80:$http:g" -i /etc/apache2/sites-available/default
	sed -e "s:443:$https:g" -i /etc/apache2/ports.conf
	sed -e "s:127.0.0.1:0.0.0.0:g" -i /etc/apache2/ports.conf
	if [ -d $DestinationPath ]; then
	    sed -e "s:/var/www:$DestinationPath:g" -i /etc/apache2/sites-available/default
	fi
fi

# config certificate if present
if [ -d /var/elasticbox/certificates ]; then
    # automated conversion of pfx into certificate and key
    expect <<SCRIPT
set timeout -1
spawn openssl pkcs12 -in `ls /var/elasticbox/certificates/*.pfx` -clcerts -nodes -nokeys -out /var/elasticbox/certificates/servercert.pem
match_max 100000
expect -exact "Enter Import Password:"
send -- "$CertificatePassword\r"
expect eof
SCRIPT

    expect <<SCRIPT
set timeout -1
spawn openssl pkcs12 -in `ls /var/elasticbox/certificates/*.pfx` -clcerts -out /var/elasticbox/certificates/file.pem -nodes
match_max 100000
expect -exact "Enter Import Password:"
send -- "$CertificatePassword\r"
expect eof
SCRIPT

    openssl rsa -in /var/elasticbox/certificates/file.pem -out /var/elasticbox/certificates/serverkey.pem
    rm /var/elasticbox/certificates/*.pfx
    rm /var/elasticbox/certificates/file.pem
  
    # add key and certificate to apache2
    if [ -f /etc/yum.conf ]; then
    	sed -e "s:SSLCertificateFile /etc/pki/tls/certs/localhost.crt:SSLCertificateFile    /var/elasticbox/certificates/servercert.pem:g" -i /etc/httpd/conf.d/ssl.conf
    	sed -e "s:SSLCertificateKeyFile /etc/pki/tls/private/localhost.key:SSLCertificateKeyFile    /var/elasticbox/certificates/serverkey.pem:g" -i /etc/httpd/conf.d/ssl.conf
    	sed -e "/DirectoryIndex/ c\ DirectoryIndex index.html index.htm index.shtml index.pl" -i  /etc/httpd/conf.d/ssl.conf
    	sed -e "s:Options FollowSymLinks:Options FollowSymLinks +ExecCGI:g" -i /etc/httpd/conf.d/ssl.conf
    	sed -e "s:443:$https:g" -i /etc/httpd/conf.d/ssl.conf
    	if [ -d $DestinationPath ] ; then
      		sed -e "s:/var/www/html:$DestinationPath:g" -i /etc/httpd/conf.d/ssl.conf
      		sed -e "s:/var/www/cgi-bin:$DestinationPath:g" -i /etc/httpd/conf.d/ssl.conf
      		sed -e "s:/var/www:$DestinationPath:g" -i /etc/httpd/conf.d/ssl.conf
    	fi
    elif [ -f /etc/debian_version ]; then
    	cp /etc/apache2/sites-available/default-ssl /etc/apache2/sites-available/ssl
    	sed -e "s/VirtualHost \*:443/VirtualHost \*:$https/g" -i /etc/apache2/sites-available/ssl
    	sed -e "s:SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem:SSLCertificateFile    /var/elasticbox/certificates/servercert.pem:g" -i /etc/apache2/sites-available/ssl
    	sed -e "s:SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key:SSLCertificateKeyFile    /var/elasticbox/certificates/serverkey.pem:g" -i /etc/apache2/sites-available/ssl
    	if [ -d $DestinationPath ] ; then
      		sed -e "s:/usr/lib/cgi-bin:$DestinationPath:g" -i /etc/apache2/sites-available/ssl
      		sed -e "s:/var/www/html:$DestinationPath:g" -i /etc/apache2/sites-available/ssl
      		sed -e "s:/var/www/cgi-bin:$DestinationPath:g" -i /etc/apache2/sites-available/ssl
      		sed -e "s:/var/www:$DestinationPath:g" -i /etc/apache2/sites-available/ssl
    	fi
    	sed -e "/SymLinksIfOwnerMatch/ aAddHandler cgi-script cgi pl" -i /etc/apache2/sites-available/ssl
    	cd /etc/apache2/sites-enabled
    	a2ensite ssl
  	fi
fi

if [ -d $DestinationPath ]; then
  	cd $DestinationPath
  	find . -type f -exec chmod 644 {} \; && find . -type d -exec chmod 755 {} \;
fi
