# 🖥️ VPS Deployment Checklist

## ✅ VPS Deployment Checklist

### 1. Prerequisites Check
- [ ] Connected to VPS: `ssh user@your-vps-ip`
- [ ] System is Ubuntu/Debian based: `cat /etc/os-release`
- [ ] Have sudo privileges: `sudo whoami`

### 2. Repository Setup
- [ ] Clone repository: `git clone https://github.com/Drwuu/n8n-saas.git`
- [ ] Navigate to directory: `cd n8n-saas`
- [ ] Check files: `ls -la`

### 3. Configuration Files
- [ ] Copy .env.prod from local machine: `scp .env.prod user@your-vps-ip:~/n8n-saas/`
- [ ] Verify .env.prod exists: `ls -la .env.prod`
- [ ] Verify domain configuration: `grep N8N_HOST .env.prod`
- [ ] Check DNS resolution: `dig your.domain.com +short`
- [ ] Verify environment variables: `cat .env.prod`

## 🚀 VPS Deployment Commands

### Automated Deployment (Recommended):
```bash
# IMPORTANT: Make sure .env.prod is in the n8n-saas directory first!
# From local machine: scp .env.prod user@your-vps-ip:~/n8n-saas/

# Deploy everything automatically
# This script will:
# - Install Docker & Docker Compose (if missing)
# - Configure firewall (SSH, HTTP, HTTPS)  
# - Create Docker networks
# - Deploy all services
./deploy-vps.sh
```

### Manual Deployment (Alternative):
```bash
# Create external network (if not done)
docker network create proxy

# Deploy production services
./up-client.sh prod prod up -d

# Check status
docker compose -f docker-compose.base.yml -f docker-compose.prod.override.yml ps
```

## 🔍 Post-Deployment Verification

### 1. Check Services
- [ ] All containers running: `docker ps`
- [ ] Check Traefik logs: `docker logs traefik`
- [ ] Check n8n logs: `docker logs n8n_prod`
- [ ] Check PostgreSQL logs: `docker logs postgres_prod`

### 2. Test Access
- [ ] Visit: `https://your.domain.com`
- [ ] SSL certificate valid (green lock)
- [ ] n8n setup wizard appears
- [ ] Create admin account
- [ ] Test webhook: `https://your.domain.com/webhook/test`

### 3. Traefik Dashboard (Optional)
- [ ] Visit: `https://traefik.your.domain.com`
- [ ] Shows n8n service routing
- [ ] SSL certificate working

## 🛠️ VPS Troubleshooting Commands

### Service Issues:
```bash
# Restart all services
./up-client.sh prod prod restart

# View all logs
docker compose -f docker-compose.base.yml -f docker-compose.prod.override.yml logs -f

# Check individual service logs
docker logs n8n_prod --tail 50
docker logs postgres_prod --tail 50
docker logs traefik --tail 50
```

### SSL Certificate Issues:
```bash
# Check Traefik logs for certificate generation
docker logs traefik | grep -i acme
docker logs traefik | grep -i certificate

# Verify Let's Encrypt volume
docker volume ls | grep letsencrypt
```

### Resource Monitoring:
```bash
# Resource usage
docker stats

# Disk space
df -h

# Network status
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Memory usage
free -h
```

## 📝 VPS Maintenance Notes

### Backup Commands:
```bash
# Backup n8n data
docker run --rm -v n8n_data_admin:/data -v $(pwd):/backup ubuntu tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz /data

# Backup database
docker exec postgres_prod pg_dump -U n8n_prod_user n8n_prod > n8n-db-backup-$(date +%Y%m%d).sql

# Backup configuration
cp .env.prod .env.prod.backup
```

### Update Commands:
```bash
# Pull latest images
docker compose -f docker-compose.base.yml -f docker-compose.prod.override.yml pull

# Restart with new images
./up-client.sh prod prod up -d

# Clean old images
docker image prune -f
```

## 🎯 VPS Deployment Complete When:

- ✅ All Docker containers running and healthy
- ✅ `https://your.domain.com` loads with valid SSL
- ✅ n8n admin setup completed successfully  
- ✅ Webhooks working: `https://your.domain.com/webhook/*`
- ✅ Database connections working
- ✅ Traefik dashboard accessible (if configured)
- ✅ All services restarting automatically

## 📧 VPS Configuration Summary

- **Domain**: your.domain.com
- **Protocol**: HTTPS (SSL auto-generated)
- **VPS IP**: your-vps-ip
- **Database**: PostgreSQL with secure credentials
- **Encryption**: Strong n8n encryption key
- **Backup**: Automated daily backups configured