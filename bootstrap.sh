#!/usr/bin/env bash

echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo " "
echo "This Debian 8 server running PHP 7.0 is using Nginx as a reverse proxy on port 8080"
echo " "
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"


# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='root'
PROJECTFOLDER='project'
WEBSERVERIP='192.168.33.23' #Change based on VagrantFile


# default stops at /var/www/html.  Leave Blank if project is in www
ADDTIONALPATH='/public_html'

echo "#######################################"
echo " "
echo "Make ${PROJECTFOLDER} folder in /var/www/html/"
echo " "
echo "#######################################"
# create project folder
[ ! -d /var/www/html/${PROJECTFOLDER} ] sudo mkdir "/var/www/html/${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

echo "#######################################"
echo " "
echo "Install Apache2 and helper utils"
echo " "
echo "#######################################"

# install apache 2.5 and php 5.5
sudo apt-get install -y apache2 python-software-properties vim htop curl git npm

echo "#######################################"
echo " "
echo "Install Nginx"
echo " "
echo "#######################################"
# install and setup Nginx + reverse proxy 
sudo apt-get install -y nginx

echo "#######################################"
echo " "
echo "Added DotDeb.org packages for PHP7.0"
echo " "
echo "#######################################"
# Needed to install PHP 7 into Debian
cat <<EOT >> /etc/apt/sources.list
deb http://packages.dotdeb.org jessie all
deb-src http://packages.dotdeb.org jessie all
EOT

wget https://www.dotdeb.org/dotdeb.gpg
sudo apt-key add dotdeb.gpg 

sudo apt-get update

echo "#######################################"
echo " "
echo "Install PHP7.0 and supporting packages"
echo " "
echo "#######################################"
#sudo apt-get install -y php7.0 php7.0-common php7.0-cli php7.0-mbstring php7.0-xml php7.0-curl php7.0-json php7.0-phpdbg php7.0-readline php7.0-mcrypt php7.0-gd php7.0-mbstring
sudo apt-get install -y php7.0-common php7.0-dev php7.0-json php7.0-opcache php7.0-cli libapache2-mod-php7.0 php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd php7.0-mcrypt php7.0-mbstring php7.0-bcmath php7.0-zip

echo "#######################################"
echo " "
echo "Install Mysql Server and PHPMyAdmin. user = root / Password = $PASSWORD"
echo " "
echo "#######################################"
# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install php7.0-mysql

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

echo "#######################################"
echo " "
echo "Setup Apache Virtual Host for /var/www/html/${PROJECTFOLDER}${ADDITIONALPATH}"
echo " "
echo "#######################################"
# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:8080>
    ServerName ${PROJECTFOLDER}.dev
    DocumentRoot "/var/www/html/${PROJECTFOLDER}${ADDITIONALPATH}"
    <Directory "/var/www/html/${PROJECTFOLDER}${ADDITIONALPATH}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/${PROJECTFOLDER}.conf

sudo a2ensite ${PROJECTFOLDER}.conf


echo "#######################################"
echo " "
echo "Setup Nginx Server Block for Reverse Proxy"
echo " "
echo "#######################################"

# setup Nginx Apache conf proxy
nginxsetupDefault=$(cat <<EOF
server {
    listen 80;
    server_name ${PROJECTFOLDER}.dev localhost;

    location / {
        proxy_pass http://${WEBSERVERIP}:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

EOF
)

echo "${nginxsetupDefault}" > /etc/nginx/sites-available/apache
sudo ln -s /etc/nginx/sites-available/apache /etc/nginx/sites-enabled/apache


echo "#######################################"
echo " "
echo "Modifications to FASTCGI.CONF"
echo " "
echo "#######################################"
# Add the following content to the FastCGI.conf
fastcgivar="$(cat <<EOF
<IfModule mod_fastcgi.c>
    AddHandler fastcgi-script .fcgi
    #FastCgiWrapper /usr/lib/apache2/suexec
    FastCgiIpcDir /var/lib/apache2/fastcgi
    AddType application/x-httpd-fastphp .php
    Action application/x-httpd-fastphp /php-fcgi
    Alias /php-fcgi /usr/lib/cgi-bin/php-fcgi
    FastCgiExternalServer /usr/lib/cgi-bin/php-fcgi -socket /run/php/php7.0-fpm.sock -pass-header Authorization
    <Directory /usr/lib/cgi-bin>
        Require all granted
    </Directory>
</IfModule>
EOF
)"

echo "${fastcgivar}" > /etc/apache2/mods-enabled/fastcgi.conf

echo "#######################################"
echo " "
echo "Change ports.conf to Listen to 8080"
echo " "
echo "#######################################"
# modify Listen from 80 to 8080 for reverse proxy
modifyports=$(cat <<EOF
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 8080

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

EOF
)

echo "${modifyports}" > /etc/apache2/ports.conf

# enable mod_rewrite
sudo a2enmod rewrite

echo "#######################################"
echo " "
echo "Restart Apache and Nginx"
echo " "
echo "#######################################"
# restart apache
service apache2 restart
# restart apache
service nginx restart

echo "#######################################"
echo " "
echo "Install Composer"
echo " "
echo "#######################################"

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "#######################################"
echo " "
echo "Copy your public key from /tmp/authorized_keys to ~./.ssh/authorized_keys"
echo " "
echo "#######################################"

sudo cat /tmp/authorized_keys >> /home/vagrant/.ssh/authorized_keys


echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo " "
echo "This Debian 8 server running PHP 7.0 is using Nginx as a reverse proxy on port 8080"
echo "Please add the following to your HOSTS file"
echo "     ${WEBSERVERIP} ${PROJECTFOLDER}.dev    "
echo " "
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"
echo "#######################################"