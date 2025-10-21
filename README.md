# 🚀 HNG13 DevOps Internship — Stage 1 Task

## 📌 Task Overview
This repository contains a production-grade Bash script (`deploy.sh`) developed for the HNG13 DevOps Internship Stage 1 task. The script automates the deployment of a Dockerized application to a remote Linux server, including environment setup, Docker/Nginx configuration, and reverse proxy setup.

## 👨‍💻 Author
**Full Name:** Solomon  
**Slack Username:** @solomon-dev

## 🛠️ Script Features
- Interactive user input collection with validation
- GitHub repository cloning using Personal Access Token (PAT)
- Remote SSH connection and environment preparation
- Docker and Docker Compose installation
- Application deployment via Docker or Docker Compose
- NGINX reverse proxy configuration
- Deployment validation and health checks
- Logging with timestamped log files
- Error handling and idempotency
- Optional cleanup flag to remove deployed resources

## 📂 Files
- `deploy.sh`: Main executable Bash script
- `README.md`: Documentation and usage guide

## ⚙️ Requirements
- Remote Linux server (Ubuntu recommended)
- SSH access with private key
- Dockerized application (Dockerfile or docker-compose.yml)
- GitHub PAT with repo access

## 🚀 Usage Instructions

### 1. Make the script executable
```bash
chmod +x deploy.sh
