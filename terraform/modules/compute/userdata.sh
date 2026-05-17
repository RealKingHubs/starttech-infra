#!/bin/bash

dnf update -y

# Install Docker
dnf install -y docker

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

# Install AWS CLI
dnf install -y awscli

# Install CloudWatch Agent
dnf install -y amazon-cloudwatch-agent

# Install SSM Agent
dnf install -y amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create app directory
mkdir -p /app