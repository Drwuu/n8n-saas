#!/usr/bin/env bash
# VPS Deployment Script for n8n SaaS

set -e

echo "🚀 Deploying n8n SaaS to VPS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed, install if missing
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker not found. Installing Docker...${NC}"
    
    # Update system
    sudo apt update
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [ "$USER" != "root" ]; then
        sudo usermod -aG docker $USER
        echo -e "${YELLOW}⚠️  Added $USER to docker group. You may need to logout/login or run 'newgrp docker'${NC}"
    fi
    
    # Clean up
    rm -f get-docker.sh
    
    echo -e "${GREEN}✅ Docker installed successfully!${NC}"
else
    echo -e "${GREEN}✅ Docker is already installed${NC}"
fi

# Check if Docker Compose is installed, install if missing
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}🔧 Docker Compose not found. Installing Docker Compose...${NC}"
    
    # Install Docker Compose plugin
    sudo apt update
    sudo apt install -y docker-compose-plugin
    
    echo -e "${GREEN}✅ Docker Compose installed successfully!${NC}"
else
    echo -e "${GREEN}✅ Docker Compose is already installed${NC}"
fi

# Configure firewall if ufw is available
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Allow SSH (important!)
    sudo ufw allow ssh 2>/dev/null || true
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp 2>/dev/null || true
    sudo ufw allow 443/tcp 2>/dev/null || true
    
    # Enable firewall if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "y" | sudo ufw enable 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Firewall configured (ports 22, 80, 443 open)${NC}"
else
    echo -e "${YELLOW}⚠️  UFW not found. Please manually configure firewall to allow ports 80 and 443${NC}"
fi

# Create external network if it doesn't exist
echo -e "${YELLOW}📡 Creating external proxy network...${NC}"
docker network create proxy 2>/dev/null || echo "Network 'proxy' already exists"

# Check if .env.prod exists
if [ ! -f ".env.prod" ]; then
    echo -e "${RED}❌ .env.prod file not found!${NC}"
    echo -e "${YELLOW}📝 Please create .env.prod file with your production configuration${NC}"
    echo -e "${YELLOW}💡 You can use .env.example as a template${NC}"
    exit 1
fi

# Configure git to skip tracking changes to template files
echo -e "${YELLOW}📝 Configuring template files to skip future changes...${NC}"
if [ -f ".env.example" ]; then
    git update-index --skip-worktree .env.example 2>/dev/null || echo "Note: .env.example not in git or already configured"
fi
if [ -f "DEPLOYMENT-CHECKLIST.local.md" ]; then
    git update-index --skip-worktree DEPLOYMENT-CHECKLIST.local.md 2>/dev/null || echo "Note: DEPLOYMENT-CHECKLIST.local.md not in git or already configured"
fi
if [ -f "DEPLOYMENT-CHECKLIST.vps.md" ]; then
    git update-index --skip-worktree DEPLOYMENT-CHECKLIST.vps.md 2>/dev/null || echo "Note: DEPLOYMENT-CHECKLIST.vps.md not in git or already configured"
fi

# Make deployment script executable
chmod +x up-client.sh

# Deploy production environment
echo -e "${YELLOW}🏗️ Deploying production environment...${NC}"
./up-client.sh prod prod up -d

# Wait a moment for services to start
sleep 10

# Check if services are running
echo -e "${YELLOW}🔍 Checking service status...${NC}"
docker compose -f docker-compose.base.yml -f docker-compose.prod.override.yml ps

echo -e "${GREEN}✅ Deployment completed!${NC}"
echo -e "${GREEN}🌐 Your n8n instance should be available at: https://$(grep N8N_HOST .env.prod | cut -d'=' -f2)${NC}"

# Show service URLs
N8N_HOST=$(grep N8N_HOST .env.prod | cut -d'=' -f2)
echo -e "${GREEN}� Service URLs:${NC}"
echo -e "   🔧 n8n Interface: https://${N8N_HOST}"
echo -e "   📊 Traefik Dashboard: https://traefik.${N8N_HOST#*.}"

echo -e "${YELLOW}⏱️  Next steps:${NC}"
echo -e "   1. Wait 2-3 minutes for SSL certificates to generate"
echo -e "   2. Visit your n8n URL and complete the setup wizard"
echo -e "   3. Create your admin account"

echo -e "${YELLOW}🔍 Monitoring commands:${NC}"
echo -e "   • Check containers: ${GREEN}docker ps${NC}"
echo -e "   • View logs: ${GREEN}docker logs traefik${NC} or ${GREEN}docker logs n8n_prod${NC}"
echo -e "   • Check SSL: ${GREEN}docker logs traefik | grep certificate${NC}"