#!/bin/bash

# Actualizar el sistema
apt-get update -y
apt-get upgrade -y

# Instalar paquetes necesarios
apt-get install -y apache2 php php-mysql php-gd php-curl php-mbstring php-xml php-imagick php-zip php-json libapache2-mod-php nfs-common

# Instalar la CLI de AWS (opcional, solo si necesitas interactuar con otros servicios AWS)
apt-get install -y awscli

# Obtener metadatos de la instancia para el nombre de host
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
HOSTNAME="wordpress-$INSTANCE_ID"
hostnamectl set-hostname "$HOSTNAME"

# Crear directorio para EFS
mkdir -p /var/www/html/wp-content

# Montar EFS para contenido compartido
# Asegúrate de reemplazar "fs-XXXXXXXXXXXX.efs.us-east-1.amazonaws.com" con tu DNS de EFS real
EFS_DNS="fs-04f7a4e6a26938ff9.efs.us-east-1.amazonaws.com"
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 "$EFS_DNS":/ /var/www/html/wp-content

# Añadir entrada en fstab para montaje automático
echo "$EFS_DNS:/ /var/www/html/wp-content nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab

# Descargar WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -a /tmp/wordpress/. /var/www/html/
rm -rf /tmp/wordpress /tmp/latest.tar.gz

# Configurar WordPress
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Reemplazar valores en wp-config.php
DB_NAME="wordpress"
DB_USER="admin"
DB_PASSWORD="rtPsvolOgO7Ar8KV4oYy"
DB_HOST="wordpress-db.c5y99z4gvpom.us-east-1.rds.amazonaws.com"

sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$DB_HOST/" /var/www/html/wp-config.php

# Generar claves únicas para seguridad
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/html/wp-config.php

# Configurar permisos
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Configurar Virtual Host para WordPress
cat <<EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Habilitar el sitio y el módulo rewrite
sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo a2dissite 000-default

# Reiniciar Apache
sudo systemctl restart apache2

sudo rm -f /var/www/html/index.html 
