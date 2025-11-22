#!/bin/bash
#
# Automated Caddy + SWAG Deployment Script for Unraid
# Run this script on your Unraid server
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║     Personal Portfolio - Caddy Deployment            ║
║     Unraid + SWAG + Caddy                            ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuration
DEPLOY_DIR="/mnt/user/appdata/portfolio"
SWAG_DIR="/mnt/user/appdata/swag"
NETWORK_NAME="swag"

# Functions
check_requirements() {
    echo -e "${BLUE}→ Checking requirements...${NC}"

    # Check if running on Unraid
    if [ ! -d "/mnt/user/appdata" ]; then
        echo -e "${YELLOW}⚠ Warning: /mnt/user/appdata not found. Are you on Unraid?${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker not found! Please install Docker.${NC}"
        exit 1
    fi

    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗ Docker Compose not found!${NC}"
        echo -e "${YELLOW}Install it via Unraid Community Applications (Docker Compose Manager)${NC}"
        exit 1
    fi

    # Check if SWAG directory exists
    if [ ! -d "$SWAG_DIR" ]; then
        echo -e "${RED}✗ SWAG directory not found at $SWAG_DIR${NC}"
        echo -e "${YELLOW}Please install SWAG from Community Applications first.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All requirements met${NC}\n"
}

get_domain() {
    echo -e "${BLUE}→ Domain Configuration${NC}"

    # Default suggestion
    DEFAULT_DOMAIN="portfolio.yourdomain.com"

    read -p "Enter your domain (e.g., $DEFAULT_DOMAIN): " DOMAIN

    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}✗ Domain cannot be empty!${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Using domain: $DOMAIN${NC}\n"
}

create_network() {
    echo -e "${BLUE}→ Setting up Docker network...${NC}"

    if docker network ls | grep -q "$NETWORK_NAME"; then
        echo -e "${GREEN}✓ Network '$NETWORK_NAME' already exists${NC}"
    else
        echo -e "${YELLOW}Creating network '$NETWORK_NAME'...${NC}"
        docker network create $NETWORK_NAME
        echo -e "${GREEN}✓ Network created${NC}"
    fi

    # Connect SWAG to network if not already connected
    if docker ps --format '{{.Names}}' | grep -q "swag"; then
        docker network connect $NETWORK_NAME swag 2>/dev/null || echo -e "${YELLOW}⚠ SWAG already connected to network${NC}"
        echo -e "${GREEN}✓ SWAG connected to network${NC}"
    else
        echo -e "${YELLOW}⚠ SWAG container not running. Make sure to start it.${NC}"
    fi

    echo
}

deploy_files() {
    echo -e "${BLUE}→ Checking deployment directory...${NC}"

    CURRENT_DIR=$(pwd)

    # Check if we're already in the right directory
    if [ "$CURRENT_DIR" == "$DEPLOY_DIR" ]; then
        echo -e "${GREEN}✓ Already in deployment directory${NC}"
    else
        # Create directory if it doesn't exist
        if [ ! -d "$DEPLOY_DIR" ]; then
            echo -e "${YELLOW}Creating directory: $DEPLOY_DIR${NC}"
            mkdir -p "$DEPLOY_DIR"
        fi

        # Check if files need to be copied
        if [ -f "./docker-compose.yml" ]; then
            echo -e "${YELLOW}Copying files to $DEPLOY_DIR...${NC}"
            cp -r ./* "$DEPLOY_DIR/"
            echo -e "${GREEN}✓ Files copied${NC}"
        else
            echo -e "${RED}✗ docker-compose.yml not found in current directory!${NC}"
            echo -e "${YELLOW}Please run this script from the portfolio directory.${NC}"
            exit 1
        fi
    fi

    echo
}

configure_swag() {
    echo -e "${BLUE}→ Configuring SWAG reverse proxy...${NC}"

    SWAG_CONF_DIR="$SWAG_DIR/nginx/proxy-confs"
    SWAG_CONF_FILE="$SWAG_CONF_DIR/portfolio.subdomain.conf"

    # Create proxy-confs directory if it doesn't exist
    mkdir -p "$SWAG_CONF_DIR"

    # Copy and configure the SWAG config
    if [ -f "./swag-config/portfolio.subdomain.conf" ]; then
        cp ./swag-config/portfolio.subdomain.conf "$SWAG_CONF_FILE"

        # Replace domain placeholder
        sed -i "s/portfolio.yourdomain.com/$DOMAIN/g" "$SWAG_CONF_FILE"

        echo -e "${GREEN}✓ SWAG configuration created at:${NC}"
        echo -e "   $SWAG_CONF_FILE"
    else
        echo -e "${YELLOW}⚠ SWAG config template not found. Creating basic config...${NC}"

        cat > "$SWAG_CONF_FILE" << EOF
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $DOMAIN;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set \$upstream_app portfolio;
        set \$upstream_port 80;
        set \$upstream_proto http;
        proxy_pass \$upstream_proto://\$upstream_app:\$upstream_port;
    }
}
EOF
        echo -e "${GREEN}✓ Basic SWAG configuration created${NC}"
    fi

    echo
}

start_container() {
    echo -e "${BLUE}→ Starting Caddy container...${NC}"

    cd "$DEPLOY_DIR"

    # Stop existing container if running
    if docker ps --format '{{.Names}}' | grep -q "portfolio"; then
        echo -e "${YELLOW}Stopping existing container...${NC}"
        docker-compose down
    fi

    # Start container
    echo -e "${YELLOW}Starting container...${NC}"
    docker-compose up -d

    # Wait a bit for container to start
    sleep 2

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "portfolio"; then
        echo -e "${GREEN}✓ Container started successfully${NC}"

        # Show logs
        echo -e "${BLUE}Container logs:${NC}"
        docker logs portfolio --tail 10
    else
        echo -e "${RED}✗ Container failed to start!${NC}"
        echo -e "${YELLOW}Check logs with: docker logs portfolio${NC}"
        exit 1
    fi

    echo
}

restart_swag() {
    echo -e "${BLUE}→ Restarting SWAG...${NC}"

    if docker ps --format '{{.Names}}' | grep -q "swag"; then
        docker restart swag
        echo -e "${GREEN}✓ SWAG restarted${NC}"

        # Wait for SWAG to be ready
        echo -e "${YELLOW}Waiting for SWAG to initialize...${NC}"
        sleep 5
    else
        echo -e "${YELLOW}⚠ SWAG container not running!${NC}"
        echo -e "${YELLOW}Please start SWAG manually.${NC}"
    fi

    echo
}

show_summary() {
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║              Deployment Complete! 🚀                  ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo -e "${BLUE}Your portfolio is now deployed!${NC}\n"

    echo -e "${GREEN}Access your site:${NC}"
    echo -e "  https://$DOMAIN\n"

    echo -e "${BLUE}DNS Configuration:${NC}"
    echo -e "${YELLOW}For local access (LAN):${NC}"
    echo -e "  Add to your router/Pi-hole DNS:"
    echo -e "  $DOMAIN → $(hostname -I | awk '{print $1}')\n"

    echo -e "${YELLOW}For external access:${NC}"
    echo -e "  1. Create A record: $DOMAIN → <your-public-ip>"
    echo -e "  2. Ensure ports 80/443 forwarded to Unraid"
    echo -e "  3. SWAG will auto-generate SSL certificate\n"

    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "  View logs:          ${YELLOW}docker logs portfolio${NC}"
    echo -e "  View SWAG logs:     ${YELLOW}docker logs swag${NC}"
    echo -e "  Restart portfolio:  ${YELLOW}cd $DEPLOY_DIR && docker-compose restart${NC}"
    echo -e "  Stop portfolio:     ${YELLOW}cd $DEPLOY_DIR && docker-compose down${NC}"
    echo -e "  Update content:     ${YELLOW}cd $DEPLOY_DIR && git pull && docker-compose restart${NC}\n"

    echo -e "${BLUE}Troubleshooting:${NC}"
    echo -e "  Test Caddy:         ${YELLOW}curl -I http://localhost:80${NC}"
    echo -e "  Test from SWAG:     ${YELLOW}docker exec swag curl -I http://portfolio:80${NC}"
    echo -e "  Check network:      ${YELLOW}docker network inspect swag${NC}"
    echo -e "  Verify SSL:         ${YELLOW}docker exec swag certbot certificates${NC}\n"

    echo -e "${GREEN}Happy self-hosting! 🏠${NC}\n"
}

# Main execution
main() {
    check_requirements
    get_domain
    create_network
    deploy_files
    configure_swag
    start_container
    restart_swag
    show_summary
}

# Run main function
main
