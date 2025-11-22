# Personal Portfolio Website

A modern, sleek personal portfolio website built with pure HTML5, CSS3, and vanilla JavaScript. Features a beautiful Tokyo Night color theme with smooth animations and interactive effects.

## Features

- **Tokyo Night Theme**: Stunning dark theme inspired by the popular Tokyo Night color scheme
- **Responsive Design**: Fully responsive layout that works on all devices
- **Smooth Animations**: Eye-catching animations and transitions throughout
- **Photography Gallery**: Dedicated photography showcase page with filtering capabilities
- **Interactive Effects**:
  - Typing animation in hero section
  - Parallax scrolling effects
  - 3D tilt effects on hover
  - Smooth page transitions
  - Lightbox for image viewing
- **No Dependencies**: Built with pure web technologies - no frameworks or libraries

## Structure

```
personal-website/
├── index.html          # Main landing page
├── photography.html    # Photography gallery page
├── styles.css          # All styles with Tokyo Night theme
├── script.js           # Interactive JavaScript features
└── README.md          # This file
```

## Pages

### Home (index.html)
- Hero section with animated typing effect
- About section highlighting professional focus
- Interests section showcasing hobbies and passions
- Smooth scroll navigation

### Photography (photography.html)
- Gallery grid with category filtering
- Placeholder cards for photography showcase
- Lightbox modal for full-size image viewing
- Keyboard navigation support

## Color Palette (Tokyo Night)

- **Background**: `#1a1b26` - Deep night blue
- **Foreground**: `#c0caf5` - Soft white-blue
- **Accent Blue**: `#7aa2f7`
- **Accent Cyan**: `#7dcfff`
- **Accent Purple**: `#bb9af7`
- **Accent Green**: `#9ece6a`
- **Accent Yellow**: `#e0af68`
- **Accent Red**: `#f7768e`

## Customization

### Adding Your Own Photos

Replace the placeholder divs in `photography.html` with your actual images:

```html
<div class="gallery-item" data-category="landscape">
    <img src="path/to/your/image.jpg" alt="Description">
</div>
```

### Updating Content

- Edit `index.html` to update your bio, skills, and interests
- Modify the `textArray` in `script.js` to change the typing animation text
- Adjust colors in `styles.css` by modifying the CSS variables in `:root`

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge
- Opera

## Performance

- No external dependencies
- Minimal HTTP requests
- Optimized CSS animations
- Fast load times
- Accessibility-friendly with reduced motion support

## Development

Simply open `index.html` in your browser to view the site locally. No build process or server required!

For a local development server:
```bash
python -m http.server 8000
# or
npx serve
```

Then visit `http://localhost:8000`

## Deployment

### Self-Hosting on Unraid with SWAG Reverse Proxy

Perfect for the self-hosting aficionado! This guide covers deploying your portfolio on Unraid with SWAG (Secure Web Application Gateway) for SSL termination and reverse proxy.

**Quick Start:**
```bash
# Use the automated deployment script
./deploy-unraid.sh

# Or specify an option directly
./deploy-unraid.sh 2  # Option 2: SWAG Direct
```

#### Prerequisites
- Unraid server running
- SWAG container already configured and running
- Domain name pointing to your server
- Ports 80/443 forwarded to your Unraid server (if accessing externally)

#### Option 1: Using NGINX Web Server (Recommended)

**1. Install NGINX from Community Applications**
```bash
# Search for "nginx" in Community Applications
# Install: binhex-nginx or linuxserver/nginx
```

**2. Configure NGINX Container**
```
Container Path: /config
Host Path: /mnt/user/appdata/nginx

Container Path: /www
Host Path: /mnt/user/appdata/nginx/www
```

**3. Deploy Your Website**
```bash
# Copy your website files to the nginx www directory
cp -r /path/to/personal-website/* /mnt/user/appdata/nginx/www/
```

**4. Create SWAG Reverse Proxy Config**

Create a new file: `/mnt/user/appdata/swag/nginx/proxy-confs/portfolio.subdomain.conf`

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name portfolio.yourdomain.com;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app nginx;  # Change to your NGINX container name
        set $upstream_port 80;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

**5. Restart SWAG**
```bash
docker restart swag
```

#### Option 2: Serve Directly from SWAG

**1. Copy Files to SWAG's WWW Directory**
```bash
# Create a subdirectory in SWAG
mkdir -p /mnt/user/appdata/swag/www/portfolio
cp -r /path/to/personal-website/* /mnt/user/appdata/swag/www/portfolio/
```

**2. Create SWAG Server Config**

Create: `/mnt/user/appdata/swag/nginx/site-confs/portfolio.conf`

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name portfolio.yourdomain.com;

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
}
```

**3. Restart SWAG**
```bash
docker restart swag
```

#### Option 3: Using a Dedicated Static Server (Caddy)

**1. Create docker-compose.yml**

Create: `/mnt/user/appdata/portfolio/docker-compose.yml`

```yaml
version: '3.8'

services:
  portfolio:
    image: caddy:alpine
    container_name: portfolio
    restart: unless-stopped
    volumes:
      - /mnt/user/appdata/portfolio/www:/usr/share/caddy:ro
      - /mnt/user/appdata/portfolio/Caddyfile:/etc/caddy/Caddyfile:ro
    networks:
      - proxynet
    expose:
      - "80"

networks:
  proxynet:
    external: true
```

**2. Create Caddyfile**

Create: `/mnt/user/appdata/portfolio/Caddyfile`

```
:80 {
    root * /usr/share/caddy
    file_server
    encode gzip
}
```

**3. Deploy Website Files**
```bash
mkdir -p /mnt/user/appdata/portfolio/www
cp -r /path/to/personal-website/* /mnt/user/appdata/portfolio/www/
```

**4. Start Container**
```bash
cd /mnt/user/appdata/portfolio
docker-compose up -d
```

**5. Configure SWAG Reverse Proxy**

Create: `/mnt/user/appdata/swag/nginx/proxy-confs/portfolio.subdomain.conf`

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name portfolio.yourdomain.com;

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
```

#### DNS Configuration

**For Local Access (LAN only):**
1. Add to your router's DNS or Pi-hole:
   ```
   portfolio.yourdomain.com -> <unraid-server-ip>
   ```

**For External Access:**
1. Create A record in your domain registrar:
   ```
   portfolio.yourdomain.com -> <your-public-ip>
   ```
2. Ensure SWAG is handling Let's Encrypt certificates
3. Verify ports 80/443 are forwarded to Unraid

#### SSL Certificate (Let's Encrypt via SWAG)

SWAG handles SSL automatically. Ensure your SWAG configuration includes:

```bash
# In SWAG docker template
URL: yourdomain.com
SUBDOMAINS: wildcard  # or include "portfolio"
VALIDATION: dns  # or http
DNSPLUGIN: cloudflare  # adjust based on your DNS provider
```

After adding the subdomain, restart SWAG and it will automatically obtain/renew certificates.

#### Performance Optimizations

**Enable Browser Caching** (add to your NGINX config):
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**Enable Compression**:
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1000;
gzip_types text/plain text/css application/javascript image/svg+xml;
```

**Security Headers** (add to your NGINX config):
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

#### Updating Your Site

Simply update the files in your chosen directory and the changes will be live immediately:

```bash
# Example for Option 2 (SWAG direct)
cp -r /path/to/updated-files/* /mnt/user/appdata/swag/www/portfolio/

# Clear browser cache or force reload (Ctrl+Shift+R)
```

#### Troubleshooting

**Site not loading:**
- Check SWAG logs: `docker logs swag`
- Verify DNS resolution: `nslookup portfolio.yourdomain.com`
- Check file permissions: `chmod -R 755 /mnt/user/appdata/swag/www/portfolio`

**SSL errors:**
- Restart SWAG: `docker restart swag`
- Check certificate: `docker exec swag certbot certificates`
- Verify DNS propagation: https://dnschecker.org

**Container networking issues:**
- Ensure containers are on the same Docker network
- Check container names match your config
- Verify with: `docker network inspect bridge`

---

### Cloud Deployment Options

This site can also be deployed to cloud platforms:
- GitHub Pages
- Netlify
- Vercel
- Cloudflare Pages
- AWS S3 + CloudFront

## License

Free to use and modify for your personal portfolio.

---

Built with ❤️ using pure HTML5, CSS3, and JavaScript
