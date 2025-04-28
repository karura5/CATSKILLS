#!/bin/bash

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar herramientas esenciales
echo "Instalando herramientas esenciales..."
sudo apt install -y curl wget unzip jq software-properties-common snapd

# Instalar AWS CLI usando Snap (classic)
echo "Instalando AWS CLI..."
if ! command -v aws &> /dev/null; then
  sudo snap install aws-cli --classic
  echo "AWS CLI instalado: $(aws --version)"
else
  echo "AWS CLI ya está instalado."
fi

# Descargar e instalar la última versión de Terraform
echo "Instalando Terraform..."
if ! command -v terraform &> /dev/null; then
  TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')
  wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  sudo mv terraform /usr/local/bin/
  rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  echo "Terraform instalado: $(terraform --version)"
else
  echo "Terraform ya está instalado."
fi

# Configurar autocompletado de Terraform
grep 'complete -C' ~/.bashrc || echo 'complete -C /usr/local/bin/terraform terraform' >> ~/.bashrc

# Configurar caché de plugins de Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
grep TF_PLUGIN_CACHE_DIR ~/.bashrc || echo 'export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"' >> ~/.bashrc

# Instalar Docker
echo "Instalando Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
  echo "Docker instalado: $(docker --version)"
else
  echo "Docker ya está instalado."
fi

# Instalar Docker Compose
echo "Instalando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
  sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose instalado: $(docker-compose --version)"
else
  echo "Docker Compose ya está instalado."
fi

# Instalar kubectl (para Kubernetes)
echo "Instalando kubectl..."
if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
  echo "kubectl instalado: $(kubectl version --client)"
else
  echo "kubectl ya está instalado."
fi

# Configurar credenciales de AWS
echo "Configurando credenciales de AWS..."
mkdir -p ~/.aws
cat <<EOT > ~/.aws/credentials
[default]
aws_access_key_id = CHANGEME
aws_secret_access_key = CHANGEMETOO
region = us-east-1
output = json
EOT

cat <<EOT > ~/.aws/config
[default]
region = us-east-1
output = json
cli_pager =
cli_history = enabled
EOT

echo "Credenciales de AWS configuradas."

# Recargar el shell
source ~/.bashrc

echo "Configuración completada. AWS CLI, Terraform, Docker, Docker Compose y kubectl están instalados."