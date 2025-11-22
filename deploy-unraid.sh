#!/bin/bash
#
# Quick Deploy Script for Unraid + SWAG
# Usage: ./deploy-unraid.sh [option]
# Options: 1 (nginx), 2 (swag-direct), 3 (caddy)
#

set -e

echo "========================================="
echo "  Personal Portfolio - Unraid Deployment"
echo "========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Unraid (optional)
if [ ! -d "/mnt/user/appdata" ]; then
    echo -e "${YELLOW}Warning: /mnt/user/appdata not found. Are you running on Unraid?${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get deployment option
if [ -z "$1" ]; then
    echo "Select deployment option:"
    echo "1) NGINX Web Server (Recommended)"
    echo "2) SWAG Direct (Simplest)"
    echo "3) Caddy Server (Advanced)"
    echo ""
    read -p "Enter option (1-3): " OPTION
else
    OPTION=$1
fi

# Get domain name
read -p "Enter your subdomain (e.g., portfolio.yourdomain.com): " DOMAIN

case $OPTION in
    1)
        echo -e "\n${GREEN}Deploying to NGINX...${NC}"
        DEST_DIR="/mnt/user/appdata/nginx/www"

        if [ ! -d "/mnt/user/appdata/nginx" ]; then
            echo -e "${RED}Error: NGINX appdata directory not found!${NC}"
            echo "Please install NGINX from Community Applications first."
            exit 1
        fi

        # Copy files
        mkdir -p "$DEST_DIR"
        cp index.html photography.html styles.css script.js "$DEST_DIR/"

        echo -e "${GREEN}Files copied to $DEST_DIR${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Create SWAG proxy config at:"
        echo "   /mnt/user/appdata/swag/nginx/proxy-confs/portfolio.subdomain.conf"
        echo ""
        echo "2. Add this configuration:"
        echo "---"
        cat << 'EOF'
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name DOMAIN;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app nginx;
        set $upstream_port 80;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
EOF
        echo "---"
        echo ""
        echo "3. Replace 'DOMAIN' with: $DOMAIN"
        echo "4. Restart SWAG: docker restart swag"
        ;;

    2)
        echo -e "\n${GREEN}Deploying directly to SWAG...${NC}"
        DEST_DIR="/mnt/user/appdata/swag/www/portfolio"

        if [ ! -d "/mnt/user/appdata/swag" ]; then
            echo -e "${RED}Error: SWAG appdata directory not found!${NC}"
            echo "Please install SWAG first."
            exit 1
        fi

        # Copy files
        mkdir -p "$DEST_DIR"
        cp index.html photography.html styles.css script.js "$DEST_DIR/"

        echo -e "${GREEN}Files copied to $DEST_DIR${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Create site config at:"
        echo "   /mnt/user/appdata/swag/nginx/site-confs/portfolio.conf"
        echo ""
        echo "2. Add this configuration:"
        echo "---"
        cat << 'EOF'
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name DOMAIN;

    include /config/nginx/ssl.conf;

    root /config/www/portfolio;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types text/plain text/css application/javascript image/svg+xml;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF
        echo "---"
        echo ""
        echo "3. Replace 'DOMAIN' with: $DOMAIN"
        echo "4. Restart SWAG: docker restart swag"
        ;;

    3)
        echo -e "\n${GREEN}Setting up Caddy deployment...${NC}"
        DEST_DIR="/mnt/user/appdata/portfolio/www"

        # Create directory structure
        mkdir -p "$DEST_DIR"
        mkdir -p "/mnt/user/appdata/portfolio"

        # Copy website files
        cp index.html photography.html styles.css script.js "$DEST_DIR/"

        # Create Caddyfile
        cat > /mnt/user/appdata/portfolio/Caddyfile << 'EOF'
:80 {
    root * /usr/share/caddy
    file_server
    encode gzip
}
EOF

        # Create docker-compose.yml
        cat > /mnt/user/appdata/portfolio/docker-compose.yml << 'EOF'
version: '3.8'

services:
  portfolio:
    image: caddy:alpine
    container_name: portfolio
    restart: unless-stopped
    volumes:
      - ./www:/usr/share/caddy:ro
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    networks:
      - swag
    expose:
      - "80"

networks:
  swag:
    external: true
EOF

        echo -e "${GREEN}Files created in /mnt/user/appdata/portfolio/${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Start the container:"
        echo "   cd /mnt/user/appdata/portfolio && docker-compose up -d"
        echo ""
        echo "2. Create SWAG proxy config at:"
        echo "   /mnt/user/appdata/swag/nginx/proxy-confs/portfolio.subdomain.conf"
        echo ""
        echo "3. Add this configuration:"
        echo "---"
        cat << 'EOF'
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name DOMAIN;

    include /config/nginx/ssl.conf;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app portfolio;
        set $upstream_port 80;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
EOF
        echo "---"
        echo ""
        echo "4. Replace 'DOMAIN' with: $DOMAIN"
        echo "5. Restart SWAG: docker restart swag"
        ;;

    *)
        echo -e "${RED}Invalid option!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Deployment preparation complete!${NC}"
echo ""
echo "Additional reminders:"
echo "- Ensure DNS points to your server"
echo "- Verify SSL certificate in SWAG"
echo "- Test access: https://$DOMAIN"
echo ""
echo -e "${YELLOW}Happy self-hosting!${NC}"
