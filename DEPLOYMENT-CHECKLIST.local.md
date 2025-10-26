# �️ Local Machine Setup for sub.yourdomain.com

## ✅ Local Machine Checklist

### 1. DNS Configuration
- [ ] Add A record: `your.domain.com` → `your-vps-ip`
- [ ] Wait for DNS propagation (1-2 hours)
- [ ] Verify DNS: `nslookup your.domain.com`
- [ ] Optional: Add A record: `traefik.your.domain.com` → `your-vps-ip`

### 2. SSH Setup
- [ ] SSH access to VPS: `ssh user@your-vps-ip`
- [ ] Generate SSH key: `ssh-keygen -t ed25519 -C "your-email@example.com"`
- [ ] Copy public key to VPS: `ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-vps-ip`
- [ ] Test key-based login: `ssh user@your-vps-ip`

### 3. Local Configuration Files
- [ ] `prod.env` configured with domain
- [ ] Strong passwords generated  
- [ ] Email addresses updated
- [ ] HTTPS enabled

### 4. File Transfer to VPS
- [ ] Copy prod.env to VPS: `scp prod.env user@your-vps-ip:~/n8n-saas/`
- [ ] Verify files on VPS

## 🚀 Local Commands to Run

### Copy files to VPS:
```bash
# Copy production environment file
scp prod.env user@your-vps-ip:~/n8n-saas/
```

### Connect to VPS for deployment:
```bash
# Connect to VPS (use template checklist for deployment steps)
ssh user@your-vps-ip
```

## 📝 Local Development Notes

### SSH Key Setup Commands:
```bash
# Generate SSH key (if not done)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/id_ed25519.pub vps@domain.com

# Test connection
ssh user@your-vps-ip
```

### Useful Local Commands:
```bash
# Check DNS resolution
nslookup sub.yourdomain.com
dig sub.yourdomain.com +short

# Should return: your-vps-ip
```

## 🎯 Local Setup Complete When:

- ✅ DNS records configured and propagated
- ✅ SSH access to VPS working
- ✅ SSH keys configured (optional but recommended)
- ✅ `prod.env` file ready for transfer
- ✅ Can connect to VPS for deployment
