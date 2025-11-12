# n8n SaaS - Multi-Client n8n Deployment

Production-ready Docker setup for hosting multiple n8n instances with automatic SSL, reverse proxy, and isolated databases.

## ✨ Features

- 🏢 **Multi-Client Support** - Separate n8n instances per client
- 🔒 **Auto SSL** - Let's Encrypt certificates via Traefik
- 🗄️ **Database Isolation** - Individual PostgreSQL per client  
- 🚀 **One-Command Deploy** - Automated VPS deployment
- 🛡️ **Production Ready** - Security & monitoring built-in

## 🚀 Quick Deploy

**Prerequisites:** VPS + Domain + SSH access

```bash
# 1. Set up shared Traefik (once per server)
git clone https://github.com/Drwuu/traefik-shared.git ~/traefik
cd ~/traefik
cp .env.example .env
# Edit .env with ACME_EMAIL, TRAEFIK_HOST, TRAEFIK_AUTH
docker compose up -d

# 2. Clone & Configure n8n-saas
git clone https://github.com/Drwuu/n8n-saas.git
cd n8n-saas
cp .env.example .env.<client-name>
# Edit .env.<client-name> with your domain & credentials

# 3. Deploy n8n client
./up-client.sh <client-name> prod up -d

# 4. Access
# Visit https://your-domain.com
```

## 📝 Configuration

Key variables in `.env.<client-name>`:

```bash
CLIENT_NAME=your-client        # Unique identifier
N8N_HOST=your-domain.com      # Your domain  
POSTGRES_PASSWORD=secure-pass  # Strong password
N8N_ENCRYPTION_KEY=64-char-hex # Generate: openssl rand -hex 32
GCS_BACKUP_BUCKET=bucket-name  # Google Cloud Storage bucket (optional)
```

## 🛠️ Local Development

```bash
cp .env.example local.env
# Edit for local settings (localhost, dev passwords, etc.)
./up-client.sh local dev up -d
# Access: http://localhost:5678
```

## 📊 Management

```bash
# Client operations
./up-client.sh <client> <dev|prod> <up|down|logs|restart>

# Check status
docker ps | grep <client>
docker logs n8n_<client>
docker logs postgres_<client>

# Traefik logs (from ~/traefik directory)
cd ~/traefik && docker logs traefik

# Manual backup (single client)
docker compose --profile backup up postgres-backup

# Automated backup (all clients)
./backup-all.sh

# Setup automated daily backups (2 AM)
crontab -e
# Add: 0 2 * * * /home/ubuntu/kizunai-n8n/backup-all.sh >> /var/log/n8n-backups.log 2>&1
```

## 🆘 Troubleshooting

**SSL Issues:** `cd ~/traefik && docker logs traefik | grep -i acme`  
**n8n Issues:** `docker logs n8n_<client>`  
**DB Issues:** `docker logs postgres_<client>`  
**Backup Issues:** `docker compose logs postgres-backup`

Check [deployment checklists](DEPLOYMENT-CHECKLIST.vps.md) for detailed troubleshooting.

## 📚 More Info

- [Detailed Setup Guide](DEPLOYMENT-CHECKLIST.vps.md)
- [n8n Docs](https://docs.n8n.io/) | [Traefik Docs](https://doc.traefik.io/)

## 🤝 Contributing

Fork → Branch → Commit → PR

---

## **Made with ❤️ for automation**
