#!/bin/bash
apt update
apt upgrade -y

# Instalar dependencias
apt install -y apache2 php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip nfs-common

# Instalar AWS CLI
apt install -y awscli

# Configurar montaje EFS
mkdir -p /var/www/html/wordpress
echo "fs-0ecb6132e787d4256.efs.us-east-1.amazonaws.com:/ /var/www/html/wordpress nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
mount -a

# Si es la primera instancia, descargar e instalar WordPress
if [ ! -f /var/www/html/wordpress/wp-config.php ]; then
  cd /tmp
  wget https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  cp -r wordpress/* /var/www/html/wordpress/
  chown -R www-data:www-data /var/www/html/wordpress/

  # Configurar wp-config.php
  cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
  sed -i "s/database_name_here/wordpress/" /var/www/html/wordpress/wp-config.php
  sed -i "s/username_here/admin/" /var/www/html/wordpress/wp-config.php
  sed -i "s/password_here/TTvZIBoY9zT21Q28RbwH/" /var/www/html/wordpress/wp-config.php
  sed -i "s/localhost/wordpress-db.cspfe1inrs2v.us-east-1.rds.amazonaws.com/" /var/www/html/wordpress/wp-config.php
  
  # Añadir claves de autenticación
  SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
  SALT="${SALT//\$/\\$}"
  sed -i "/define( 'AUTH_KEY'/,/define( 'NONCE_SALT'/ d" /var/www/html/wordpress/wp-config.php
  echo "$SALT" >> /var/www/html/wordpress/wp-config.php
  
  # Configurar para múltiples servidores
  echo "define('FS_METHOD', 'direct');" >> /var/www/html/wordpress/wp-config.php
fi

# Configurar Apache
cat > /etc/apache2/sites-available/wordpress.conf << EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html/wordpress
    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2ensite wordpress.conf
a2dissite 000-default.conf
a2enmod rewrite
systemctl restart apache2

# Mostrar finalización
echo "Instalación de WordPress completada"
