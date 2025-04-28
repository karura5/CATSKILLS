HOLA QUIERO QUE ME AYUDES A IMPLEMENTAR, INSTALAR Y CONFIGURAR UN WORDPRESS DE ALTA DISPONIBILIDAD Y ESCABILIDAD EN EC2. 
QUIERO REALIZAR ESTA ACTIVIDAD EN LA CONSOLA DE AWS, QUIERO CONSOLA DE AWS. QUE PRIMERO ME AYUDES A ESTABLECER UNA ESTRATEGIA PORQUE TENDRE 3 HORAS PARA REALIZAR TODO ESTO. LUEGO DE LA ESTRATEGIA QUIERO QUE EMPIECES CREADO UN DIAGRAMA Y QUIERO QUE ME EXPLIQUES PORQUE ESTA OPCION ES LA MEJOR PARA ESTA ACTIVIDAD. ES IMPORTANTE QUE ME DES EXPLICACION EN CADA PASO QUE DES. QUIERO QUE ME HAGAS UN DIAGRAMA Y QUE ME GUIES PASO A PASO DESDE LA CONSOLA DE AWS PARA COMPLETAR ESTA ACTIVIDAD. ALGO QUE QUIERO QUE TENGAS EN CUENTA ES QUE MI HOSTED ZONE SE LLAMA BLOG.KARURA.CAT Y QUE LUEGO AÑADIRE UN REGISTRO DE TIPO CNAME PARA ASOCIARLO A MI ALB. Y MI CUENTA DE AWS ES ACADDEMY ASI QUE ESTA LIMITADA, SOLO TENGO UN ROL Y NO PUEDO TOCAR IAM NI NADA. ES ALGO QUE TENGAS EN CUENTA. LOS SIQUIENTES PUNTOS SON TODO LO QUE TIENE QUE CUMPLIR, QUIERO REALIZAR TODOS, ABSOLUTAMENTE TODOS, AYUDAME PASO A PASO Y QUIERO QUE SEA TOTALMENTE FUNCIONAL!

1. Networking
Ha creado una VPC específica para el proyecto
Ha creado al menos 2 subredes públicas en diferentes zonas de disponibilidad
Ha creado al menos 2 subredes privadas en diferentes zonas de disponibilidad
Ha configurado tablas de rutas adecuadamente para subredes públicas y privadas
Ha implementado NAT Gateway para permitir tráfico saliente desde subredes privadas
Ha configurado correctamente los grupos de seguridad con acceso mínimo necesario
USAR LA CONSOLA DE AWS, CONSOLA, Y ELEGIR LA ELECCION DE "VPC AND MORE" no quiero crear subredes,no quiero crear tablas de rutas,no quiero crear igw ni ngw.

2. Servidores Web
Ha utilizado una AMI apropiada y actualizada
Ha creado una plantilla de lanzamiento o configuración de lanzamiento
Ha implementado un grupo de Auto Scaling
Ha configurado políticas de escalado adecuadas (CPU o memòria)
Ha instalado y configurado correctamente WordPress en las instancias
Ha utilizado script de inicio para automatizar la configuración
Ha configurado el escalado en múltiples zonas de disponibilidad
Quiero usar una plantilla de lanzamiento UBUNTU.

3. Base de Datos
Ha implementado Amazon RDS para MySQL/MariaDB en vez de una BD local
Ha configurado Multi-AZ para alta disponibilidad de la base de datos
Ha implementado instancias de réplica de lectura
Ha configurado grupos de seguridad adecuados para la base de datos
Ha configurado copias de seguridad automáticas
Ha utilizado un tamaño de instancia apropiado para la carga esperada
Quiero usar RDS de alta disponibilidad Multi-AZ y mysql.

4. Almacenamiento Compartido
Ha implementado EFS para contenido compartido de WordPress
Ha montado EFS en todas las instancias EC2
Ha configurado los puntos de acceso EFS correctamente
Ha establecido permisos adecuados en el sistema de archivos
Ha configurado el montaje automático de EFS en el arranque

5. Balanceo de Carga
Ha implementado un Application Load Balancer (ALB)
Ha configurado el ALB para distribuir tráfico entre múltiples zonas de disponibilidad
Ha configurado health checks apropiados
Ha configurado SSL/TLS en el balanceador de carga
Ha configurado el sticky sessions si es necesario para WordPress

6. Seguridad
Ha implementado HTTPS en el balanceador de carga
Ha utilizado AWS Certificate Manager para certificados SSL/TLS ACM
Ha aplicado actualizaciones al sistema operativo
Ha configurado acceso SSH seguro (claves bastion host etc)
Ha implementado WAF para protección contra ataques web

7. Monitorización y Alarmas
Ha configurado CloudWatch para monitorizar recursos críticos
Ha creado alguna alarma para métricas importantes (CPU o memòria)
Ha configurado logs para aplicaciones y sistemas
Ha implementado dashboards para visualizar el estado del sistema

8. Respaldo y Recuperación
Ha configurado copias de seguridad automáticas de EFS
Ha implementado estrategia de backup para contenidos de WordPress
Ha documentado procedimientos de recuperación ante desastres

9. Optimización
Ha implementado Cloudflare con route53 y acm para CDN
Ha configurado almacenamiento en caché para contenido estático
Ha optimizado las instancias EC2 para el rendimiento de WordPress
Ha configurado el escalado programado para horas de mayor tráfico

10. Documentación
Ha proporcionado documentación clara de la arquitectura
Ha incluido diagramas de la infraestructura
Ha documentado las decisiones de diseño y justificaciones
Ha proporcionado guías de mantenimiento y operación

