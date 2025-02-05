#!/bin/bash

# Exit on any error
set -e

echo "Starting Docker installation..."

# Update package list
sudo apt update -y

# Install prerequisites
echo "Installing prerequisites..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt update -y

# Show Docker versions available
echo "Available Docker versions:"
apt-cache policy docker-ce

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker-ce

# Check Docker status
echo "Checking Docker status..."
sudo systemctl status docker

# Add user to docker group
echo "Adding current user to docker group..."
sudo usermod -aG docker ubuntu

# Test Docker installation
echo "Testing Docker installation..."
docker run hello-world

# Install Docker Compose
echo "Installing Docker Compose..."
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Install Docker Compose through apt
echo "Installing Docker Compose through apt..."
sudo apt install -y docker-compose

# Create OpenVPN directory and compose file
echo "Creating OpenVPN directory and compose file..."
mkdir -p openvpn
cd openvpn

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: "3.5"
services:
    openvpn:
       container_name: openvpn
       image: d3vilh/openvpn-server:latest
       privileged: true
       ports: 
          - "1194:1194/udp"
       environment:
           TRUST_SUB: 10.0.70.0/24
           GUEST_SUB: 10.0.71.0/24
           HOME_SUB: 192.168.88.0/24
       volumes:
           - ./pki:/etc/openvpn/pki
           - ./clients:/etc/openvpn/clients
           - ./config:/etc/openvpn/config
           - ./staticclients:/etc/openvpn/staticclients
           - ./log:/var/log/openvpn
           - ./fw-rules.sh:/opt/app/fw-rules.sh
           - ./server.conf:/etc/openvpn/server.conf
       cap_add:
           - NET_ADMIN
       restart: always
    openvpn-ui:
       container_name: openvpn-ui
       image: d3vilh/openvpn-ui:latest
       environment:
           - OPENVPN_ADMIN_USERNAME=admin
           - OPENVPN_ADMIN_PASSWORD=gagaZush
       privileged: true
       ports:
           - "8080:8080/tcp"
       volumes:
           - ./:/etc/openvpn
           - ./db:/opt/openvpn-ui/db
           - ./pki:/usr/share/easy-rsa/pki
           - /var/run/docker.sock:/var/run/docker.sock:ro
       restart: always
EOF

# Create required directories
mkdir -p {pki,clients,config,staticclients,log,db}

echo "Installation complete! OpenVPN compose file created in openvpn/docker-compose.yml"
echo "To start OpenVPN, navigate to the openvpn directory and run: docker-compose up -d"
