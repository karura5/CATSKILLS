#!/bin/bash
sudo apt update
sudo apt install -y mysql-client

## compte que ara no estem "dintre" de la instància i per tant ens cal indicar ON està ( -h) 
# cat wordpress.sql | sudo mysql -u admin -pUltr4ins3gur4! -h efs24365.cxtfe4jkj9h2.us-east-1.rds.amazonaws.com


sudo apt update
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-client \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip

sudo apt install -y nfs-common

##
##
sudo mkdir -p /srv/www

# cal informar el mount point generat prèviament
unitat_compartida=fs-04f7a4e6a26938ff9.efs.us-east-1.amazonaws.com:/

punt_de_muntatge=/srv/www

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $unitat_compartida $punt_de_muntatge 

# si no existeix el directori és que és el 1er cop i caldrà descarregar-lo
if [ ! -d /srv/www/wordpress ]; then  curl https://wordpress.org/latest.tar.gz | sudo tar zx -C /srv/www ; sudo chown www-data: /srv/www/wordpress;  fi

# com que acabem de crear la instància caldrà afegir a /etc/fstab el recurs compartit pq el munte de nou quan reiniciem
grep $unitat_compartida /etc/fstab || sudo tee -a /etc/fstab << EOF
$unitat_compartida $punt_de_muntatge nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0
EOF

# ip interna # per validar que hi ha diferents instàncies
sudo tee /srv/www/wordpress/ip-interna.php << EOF
ip interna: <?php echo shell_exec("hostname -I"); ?>
EOF

sudo chown -R www-data:www-data /srv/www

##
##
# AllowOverride Limit Options FileInfo
sudo tee /etc/apache2/sites-available/wordpress.conf << EOF
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride All
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

##
##
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo service apache2 reload

creat_en_aquest=false
if [ ! -f /srv/www/wordpress/wp-config.php ]; then sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php; creat_en_aquest=true; fi

if $creat_en_aquest; then
sudo -u www-data sed -i 's/database_name_here/wordpressdb01/' /srv/www/wordpress/wp-config.php;
sudo -u www-data sed -i 's/username_here/admin/' /srv/www/wordpress/wp-config.php;
sudo -u www-data sed -i 's/password_here/rtPsvolOgO7Ar8KV4oYy/' /srv/www/wordpress/wp-config.php;
sudo -u www-data sed -i 's/localhost/wordpress-db.c5y99z4gvpom.us-east-1.rds.amazonaws.com/' /srv/www/wordpress/wp-config.php;
echo  "define('FS_METHOD', 'direct');" | sudo -u www-data tee -a /srv/www/wordpress/wp-config.php;
fi