# ######### Collect Parameters from User Input
read -p "Git Repository URL: " repo_url
read -p "GitHub Personal Access Token: " pat
read -p "Branch name [default: main]: " branch
branch=${branch:-main}
read -p "Remote SSH Username: " ssh_user
read -p "Remote Server IP: " server_ip
read -p "SSH Key Path: " ssh_key
read -p "Application Port (internal container port): " app_port
# ######### Add basic validation
if [[ -z "$repo_url" || -z "$pat" || -z "$ssh_user" || -z "$server_ip" || -z "$ssh_key" || -z "$app_port" ]]; then
  echo "Missing required input. Exiting."
  exit 1
fi
# ######### Clone the Repository
# #########  Use PAT for authentication
git_url=$(echo "$repo_url" | sed "s|https://|https://$pat@|")
repo_name=$(basename "$repo_url" .git)

if [ -d "$repo_name" ]; then
  cd "$repo_name"
  git pull origin "$branch"
else
  git clone -b "$branch" "$git_url"
  cd "$repo_name"
fi
# ######### Verify Dockerfile or docker-compose.yml
if [[ -f "Dockerfile" || -f "docker-compose.yml" ]]; then
  echo "Docker configuration found."
else
  echo "No Dockerfile or docker-compose.yml found. Exiting."
  exit 2
fi
# ######### SSH into Remote Server
ssh -i "$ssh_key" "$ssh_user@$server_ip" "echo Connected"
# ######### Prepare Remote Environment
ssh -i "$ssh_key" "$ssh_user@$server_ip" << EOF
  sudo apt update
  sudo apt install -y docker.io docker-compose nginx
  sudo usermod -aG docker \$USER
  sudo systemctl enable docker nginx
  sudo systemctl start docker nginx
EOF

# ######### Deploy Dockerized Application
# ######### Transfer files:
scp -i "$ssh_key" -r . "$ssh_user@$server_ip:/home/$ssh_user/app"

# ######### Run containers:
ssh -i "$ssh_key" "$ssh_user@$server_ip" << EOF
  cd /home/$ssh_user/app
  if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
  else
    docker build -t myapp .
    docker run -d -p $app_port:$app_port myapp
  fi
EOF

# ######### Configure NGINX as Reverse Proxy
# ######### Generate config
nginx_config="
server {
    listen 80;
    location / {
        proxy_pass http://localhost:$app_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
"
ssh -i "$ssh_key" "$ssh_user@$server_ip" << EOF
  echo "$nginx_config" | sudo tee /etc/nginx/sites-available/app.conf
  sudo ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
  sudo nginx -t && sudo systemctl reload nginx
EOF

# ######### Validate Deployment
ssh -i "$ssh_key" "$ssh_user@$server_ip" << EOF
  docker ps
  curl -I http://localhost
EOF

# ######### Logging and Error Handling
log_file="deploy_$(date +%Y%m%d).log"
exec > >(tee -a "$log_file") 2>&1
trap 'echo "Error occurred. Check $log_file"; exit 99' ERR

# ######### Idempotency and Cleanup
if [[ "$1" == "--cleanup" ]]; then
  ssh -i "$ssh_key" "$ssh_user@$server_ip" << EOF
    docker-compose down || docker stop myapp && docker rm myapp
    sudo rm -rf /home/$ssh_user/app
    sudo rm /etc/nginx/sites-enabled/app.conf
    sudo systemctl reload nginx
EOF
  exit 0
fi

# #########