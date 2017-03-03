# vagrant-deb8-php7-reverse
A Vagrant Box with Bootstrap script that installs Debian 8 LAMP Stack with PHP7.0 and an Nginx Reverse Proxy built in. 

# Check your WWW mappings

The VagrantFile is set to map /var/www/html inside the Debian 8 machine to a 'www' folder inside this project.  I have a WWW folder elsewhere on my machine that I symlink such as: 

`ln -s /Users/username/www www` 

Which leaves me with VagrantFile, bootstrap.sh, a readme.md, and a `www` directory 

# Nginx with Reverse Proxy 

This Bootstrap file will run through all the necessary installs to setup LAMP with PHP7 and an Nginx Reverse Proxy on port 8080 inside the Debian 8 machine. 

Enter a `project name` at the top of the `bootstrap.sh` file, a `additionalpath` such as `/public_html` if it pertains to your code structure, and change the `IP Address` in both VagrantFile and bootstrap.sh if you want something different than 192.168.33.23
