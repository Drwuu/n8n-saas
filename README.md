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
# 1. Clone & Configure
git clone https://github.com/Drwuu/n8n-saas.git
cd n8n-saas
cp .env.example .env.prod
# Edit .env.prod with your domain & credentials

# 2. Deploy to VPS
scp .env.prod user@your-vps:~/n8n-saas/
ssh user@your-vps 'cd n8n-saas && ./deploy-vps.sh'

# 3. Access
# Visit https://your-domain.com
```

## � Configuration

Key variables in `.env.prod`:

```bash
CLIENT_NAME=your-client        # Unique identifier
N8N_HOST=your-domain.com      # Your domain  
POSTGRES_PASSWORD=secure-pass  # Strong password
N8N_ENCRYPTION_KEY=64-char-hex # Generate: openssl rand -hex 32
ACME_EMAIL=you@domain.com     # For SSL certificates
```

## 🛠️ Local Development

```bash
cp .env.example local.env
# Edit for local settings (localhost, dev passwords, etc.)
./up-client.sh local dev up -d
# Access: http://localhost:5678
```

## � Management

```bash
# Client operations
./up-client.sh <client> <dev|prod> <up|down|logs|restart>

# Check status
docker ps
docker logs traefik
docker logs n8n_<client>

# Backup (run with --profile backup)
docker compose --profile backup run postgres-backup
```

## 🆘 Troubleshooting

**SSL Issues:** `docker logs traefik | grep -i acme`  
**n8n Issues:** `docker logs n8n_<client>`  
**DB Issues:** `docker logs postgres_<client>`

Check [deployment checklists](DEPLOYMENT-CHECKLIST.vps.md) for detailed troubleshooting.

## 📚 More Info

- [Detailed Setup Guide](DEPLOYMENT-CHECKLIST.vps.md)
- [n8n Docs](https://docs.n8n.io/) | [Traefik Docs](https://doc.traefik.io/)

## 🤝 Contributing

Fork → Branch → Commit → PR

---

**Made with ❤️ for automation**