# Buscar la AMI de Ubuntu más reciente
data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  owners = ["099720109477"] # Canonical
}

# Instancia EC2
resource "aws_instance" "chatbot_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"  
  key_name               = "vockey" 
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
user_data = <<-EOF
  #!/bin/bash
  # Actualizar paquetes
  apt-get update
  apt-get upgrade -y
  
  # Instalar Nginx
  apt-get install -y nginx
  
  # Configurar Nginx para escuchar en puerto 80
  cat > /etc/nginx/sites-available/default << 'EOL'
  server {
      listen 80 default_server;
      listen [::]:80 default_server;
      
      root /var/www/html;
      index index.html index.htm index.nginx-debian.html;
      
      server_name _;
      
      location / {
          try_files $uri $uri/ =404;
      }
      
      # Configuración para API del chatbot (ejemplo)
      location /api {
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
      }
  }
  EOL
  
  # Crear un HTML básico como página de inicio
  cat > /var/www/html/index.html << 'EOL'
  <!DOCTYPE html>
  <html>
  <head>
      <title>Chatbot de Salud Mental</title>
      <style>
          body {
              font-family: Arial, sans-serif;
              margin: 0;
              padding: 20px;
              text-align: center;
          }
          h1 {
              color: #333;
          }
          .chat-container {
              max-width: 600px;
              margin: 0 auto;
              border: 1px solid #ddd;
              padding: 20px;
              border-radius: 5px;
          }
          #chat-messages {
              min-height: 300px;
              margin-bottom: 10px;
              text-align: left;
              padding: 10px;
              background: #f9f9f9;
              border-radius: 5px;
          }
          #message-input {
              width: 70%;
              padding: 8px;
          }
          button {
              padding: 8px 15px;
              background: #4CAF50;
              color: white;
              border: none;
              border-radius: 3px;
              cursor: pointer;
          }
      </style>
  </head>
  <body>
      <h1>Chatbot de Salud Mental</h1>
      <div class="chat-container">
          <div id="chat-messages">
              <p><strong>Chatbot:</strong> Hola, soy tu asistente virtual. ¿En qué puedo ayudarte hoy?</p>
          </div>
          <div>
              <input type="text" id="message-input" placeholder="Escribe tu mensaje...">
              <button onclick="sendMessage()">Enviar</button>
          </div>
      </div>
      
      <script>
          function sendMessage() {
              const messageInput = document.getElementById('message-input');
              const chatMessages = document.getElementById('chat-messages');
              
              if (messageInput.value.trim() !== '') {
                  // Añadir mensaje del usuario
                  chatMessages.innerHTML += '<p><strong>Tú:</strong> ' + messageInput.value + '</p>';
                  
                  // Simulación de respuesta (aquí conectarías con tu API real)
                  setTimeout(() => {
                      chatMessages.innerHTML += '<p><strong>Chatbot:</strong> Estoy aquí para escucharte. ¿Puedes contarme más sobre cómo te sientes?</p>';
                      chatMessages.scrollTop = chatMessages.scrollHeight;
                  }, 1000);
                  
                  messageInput.value = '';
              }
          }
      </script>
  </body>
  </html>
  EOL
  
  # Reiniciar Nginx
  systemctl restart nginx
  
  # Instalar herramientas adicionales que puedas necesitar
  apt-get install -y git nodejs npm
  
  # Crear directorio para la aplicación
  mkdir -p /opt/chatbot
  
  echo "Instalación completada" > /var/log/user-data-complete.log
EOF
  
  tags = {
    Name = "chatbot-server"
  }
  
  # Importante: Asegurar que la instancia tenga tiempo de inicializarse completamente
  depends_on = [
    aws_internet_gateway.chatbot_igw
  ]
}

# Output para mostrar la IP pública
output "ec2_public_ip" {
  value = aws_instance.chatbot_ec2.public_ip
}

output "load_balancer_dns" {
  value = aws_lb.chatbot_alb.dns_name
}