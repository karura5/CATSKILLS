#!/bin/bash

# Crear el Security Group
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name sg2 --description "Permitir puertos 22, 80 y 443" --query 'GroupId' --output text)

# Configurar reglas de ingreso
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

# Lanzar la instancia EC2
aws ec2 run-instances --image-id ami-084568db4383264d4 --count 1 --instance-type t2.micro --security-group-ids $SECURITY_GROUP_ID --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=pub2}]'
