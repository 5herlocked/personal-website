# Caddy Deployment Guide for Unraid + SWAG

This guide will help you deploy your portfolio using Caddy with SWAG reverse proxy on Unraid.

## Prerequisites

- Unraid server running
- SWAG container configured and running
- Docker Compose Plugin installed on Unraid
- Domain name configured

## Quick Deployment Steps

### 1. Clone/Copy Repository to Unraid

```bash
# SSH into your Unraid server
ssh root@<unraid-ip>

# Create the portfolio directory
mkdir -p /mnt/user/appdata/portfolio

# Clone or copy the repository files to this location
# Option A: If you have git
cd /mnt/user/appdata/portfolio
git clone <your-repo-url> .

# Option B: Or copy files manually via Unraid share
# Copy all files to: \\<unraid-ip>\appdata\portfolio\
```

### 2. Verify Files are in Place

```bash
cd /mnt/user/appdata/portfolio
ls -la

# You should see:
# - docker-compose.yml
# - Caddyfile
# - index.html
# - photography.html
# - styles.css
# - script.js
# - swag-config/
```

### 3. Create Docker Network (if it doesn't exist)

```bash
# Check if 'swag' network exists
docker network ls | grep swag

# If it doesn't exist, create it
docker network create swag

# Connect your SWAG container to this network if not already
docker network connect swag swag
```

### 4. Start the Caddy Container

```bash
cd /mnt/user/appdata/portfolio
docker-compose up -d

# Verify it's running
docker ps | grep portfolio

# Check logs
docker logs portfolio
```

### 5. Configure SWAG Reverse Proxy

```bash
# Copy the SWAG configuration
cp /mnt/user/appdata/portfolio/swag-config/portfolio.subdomain.conf \
   /mnt/user/appdata/swag/nginx/proxy-confs/

# Edit the file and replace 'portfolio.yourdomain.com' with your actual domain
nano /mnt/user/appdata/swag/nginx/proxy-confs/portfolio.subdomain.conf

# Or use sed to replace it
sed -i 's/portfolio.yourdomain.com/your-actual-domain.com/g' \
  /mnt/user/appdata/swag/nginx/proxy-confs/portfolio.subdomain.conf
```

### 6. Restart SWAG

```bash
docker restart swag

# Check SWAG logs for any errors
docker logs swag
```

### 7. Configure DNS

**Option A: Local Access Only (LAN)**
- Add to your router's DNS or Pi-hole:
  ```
  portfolio.yourdomain.com → <unraid-server-ip>
  ```

**Option B: External Access**
- Create A record in your domain registrar:
  ```
  portfolio.yourdomain.com → <your-public-ip>
  ```
- Ensure ports 80/443 are forwarded to your Unraid server

### 8. Verify SSL Certificate

SWAG should automatically obtain an SSL certificate. Verify with:

```bash
# Check if certificate exists
docker exec swag ls -la /config/keys/letsencrypt/

# Or check certificate details
docker exec swag certbot certificates
```

### 9. Test Your Site

Visit `https://portfolio.yourdomain.com` in your browser.

You should see your portfolio with a valid SSL certificate!

## Updating Your Portfolio

To update your portfolio content:

```bash
# SSH to Unraid
ssh root@<unraid-ip>

# Navigate to portfolio directory
cd /mnt/user/appdata/portfolio

# Pull latest changes (if using git)
git pull

# Or edit files directly, then restart Caddy
docker-compose restart

# Changes should be live immediately
```

## Using Unraid UI (Alternative Method)

### Via Docker Compose Manager Plugin

1. Install "Docker Compose Manager" from Community Applications
2. Navigate to Docker Compose Manager in Unraid UI
3. Add new compose stack:
   - Name: `portfolio`
   - Compose File: Browse to `/mnt/user/appdata/portfolio/docker-compose.yml`
4. Click "Compose Up"

### Via Portainer (if installed)

1. Open Portainer (usually at `http://<unraid-ip>:9000`)
2. Go to Stacks → Add Stack
3. Name: `portfolio`
4. Upload: `docker-compose.yml` or paste its contents
5. Deploy the stack

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs portfolio

# Verify network exists
docker network ls | grep swag

# Ensure no port conflicts
docker ps | grep :80
```

### Site not accessible

```bash
# Check SWAG logs
docker logs swag

# Verify DNS resolution
nslookup portfolio.yourdomain.com

# Test from Unraid server itself
curl -I http://localhost:80  # Should return 200 from Caddy

# Check if SWAG can reach Caddy
docker exec swag curl -I http://portfolio:80
```

### SSL Certificate Issues

```bash
# Restart SWAG
docker restart swag

# Force certificate renewal
docker exec swag certbot renew --force-renewal

# Check SWAG configuration
docker exec swag nginx -t
```

### Container networking issues

```bash
# Ensure both containers are on same network
docker network inspect swag

# Should show both 'swag' and 'portfolio' containers

# Reconnect if needed
docker network connect swag portfolio
docker network connect swag swag
```

## Performance Optimizations

The Caddyfile already includes:
- ✅ Gzip and Zstd compression
- ✅ Browser caching (1 year for static assets)
- ✅ Security headers (XSS protection, MIME sniffing prevention)
- ✅ Efficient file serving

## Monitoring

```bash
# View real-time logs
docker logs -f portfolio

# Check resource usage
docker stats portfolio

# View Caddy metrics (if enabled)
curl http://localhost:80/metrics
```

## Backup

To backup your portfolio:

```bash
# Backup entire directory
tar -czf portfolio-backup-$(date +%Y%m%d).tar.gz \
  /mnt/user/appdata/portfolio/

# Or use Unraid's built-in backup tools
```

## Stopping/Removing

```bash
# Stop container
cd /mnt/user/appdata/portfolio
docker-compose down

# Remove completely (including volumes)
docker-compose down -v

# Remove network (only if no other services use it)
docker network rm swag
```

## Additional Configuration

### Custom Domain in Caddyfile

If you want Caddy to handle SSL directly (not recommended with SWAG):

```caddyfile
portfolio.yourdomain.com {
    root * /usr/share/caddy
    file_server
    encode gzip zstd
}
```

### Multiple Sites

You can host multiple sites by:
1. Adding more services to docker-compose.yml
2. Creating separate SWAG proxy configs for each
3. Using different subdomains

## Security Checklist

- ✅ SSL/TLS enabled via SWAG
- ✅ Security headers configured
- ✅ Container runs as non-root
- ✅ Read-only filesystem for website files
- ✅ No unnecessary ports exposed
- ✅ Automatic restarts enabled

## Support

For issues:
- Check Unraid forums: https://forums.unraid.net/
- SWAG documentation: https://docs.linuxserver.io/images/docker-swag
- Caddy documentation: https://caddyserver.com/docs/

---

Enjoy your self-hosted portfolio! 🚀
