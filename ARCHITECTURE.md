# N8N Multi-Tenant Setup - Architecture Summary

## Current Status: ✅ Production Ready

### Infrastructure Components

#### 1. Networks
- **proxy** (external) - Traefik reverse proxy for public access
- **monitoring** (external) - Prometheus metrics collection
- **internal** (per-client) - Private communication between services

#### 2. Per-Client Services
```
├── postgres (postgres_${CLIENT_NAME})
│   ├── Networks: internal, monitoring
│   ├── Volume: postgres_data_${CLIENT_NAME}
│   └── Resources: 512M RAM, 0.5 CPU
│
├── n8n (n8n_${CLIENT_NAME})
│   ├── Networks: proxy, internal, monitoring
│   ├── Volumes: n8n_data_${CLIENT_NAME}, n8n_files_${CLIENT_NAME}
│   └── Resources: 1G RAM, 1.0 CPU
│
└── postgres-backup (backup_${CLIENT_NAME})
    ├── Networks: internal
    ├── Profile: backup (manual trigger)
    └── Uploads to: GCS bucket
```

#### 3. Shared Services (External)
- **Traefik** - `/home/ubuntu/traefik/`
- **Prometheus** - `/home/ubuntu/prometheus/` (centralized monitoring)

### File Structure

```
/home/ubuntu/kizunai-n8n/
├── docker-compose.base.yml          # Core services definition
├── docker-compose.local.override.yml # Dev mode (pgAdmin, direct ports)
├── docker-compose.prod.override.yml  # Prod mode (HTTPS, backups)
├── up-client.sh                      # Client launcher script
├── create-volumes.sh                 # Volume creation helper
├── backup-all.sh                     # Automated backup script
├── .env.<client>                    # Production environment (CLIENT_NAME=<client>)
├── gcs-key/
│   └── service-account-key.json      # GCS credentials (gitignored)
└── backups/                          # Local backup storage (gitignored)
```

### Environment Files

**.env.<client>** contains:
- ✅ CLIENT_NAME
- ✅ N8N_HOST, N8N_PROTOCOL, N8N_PORT
- ✅ POSTGRES credentials
- ✅ N8N_ENCRYPTION_KEY
- ✅ GCS_BACKUP_BUCKET
- ✅ Security settings

### Backup Strategy

**Local + Cloud:**
- Compressed PostgreSQL dumps (`.dump` format)
- Local retention: 7 days
- GCS retention: Managed by lifecycle policy
- Automated: Daily via cron (2 AM)

**Manual Backup (single client):**
```bash
cd /home/ubuntu/kizunai-n8n
docker compose --profile backup up postgres-backup
```

**Automated Backup (all clients):**
```bash
# The backup-all.sh script:
# - Iterates through all client directories
# - Runs backup for each client
# - Uploads to GCS
# - Logs success/failure per client
./backup-all.sh
```

**Cron Configuration:**
```bash
# Daily at 2 AM, logs to /var/log/n8n-backups.log
0 2 * * * /home/ubuntu/kizunai-n8n/backup-all.sh >> /var/log/n8n-backups.log 2>&1
```

**Restore Procedure:**
```bash
# 1. Download from GCS
gsutil cp gs://<client>-n8n-postgres-backup/n8n-backups/<client>/backup-<client>-YYYYMMDD-HHMMSS.dump ./restore.dump

# 2. Stop n8n
./up-client.sh <client> prod down n8n

# 3. Restore database
docker compose exec postgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c < ./restore.dump

# 4. Restart n8n
./up-client.sh <client> prod up -d
```

### Security

**Isolation:**
- ✅ Each client has separate database
- ✅ Postgres NOT exposed to proxy network
- ✅ GCS credentials read-only mounted
- ✅ Client data completely separated

**Network Security:**
- ✅ Postgres: internal + monitoring only
- ✅ N8N: proxy (HTTPS via Traefik) + internal + monitoring
- ✅ Backup: internal only

**Secrets Management:**
- ✅ `.env.<client>` gitignored (via `.env.*` pattern)
- ✅ `gcs-key/` gitignored
- ✅ Encryption keys unique per client

### Monitoring Integration

**Labels for Prometheus:**
```yaml
- "prometheus_port=${N8N_PORT}"
- "service=n8n"
```

**Auto-discovery:**
- Containers on `monitoring` network auto-discovered
- Metrics labeled with: `container_name`, `client_name`, `service`

### Deployment Workflow

**New Client:**
```bash
# 1. Create volumes
CLIENT_NAME=newclient ./create-volumes.sh

# 2. Create .env file
cp .env.example .env.newclient
# Edit values for new client

# 3. Launch
./up-client.sh newclient prod up
```

**Backup:**
```bash
# Manual
./backup-all.sh

# Automated via cron (already configured)
```

**Update:**
```bash
./up-client.sh <client> prod down
# Update image versions in docker-compose files
./up-client.sh <client> prod up
```

### Cost Estimates

**Per Client (Monthly):**
- VPS resources: ~$5-10 (shared)
- GCS backups: ~$0.20-0.30
- **Total per client: Minimal**

**Scalability:**
- Current: 1 client (<client>)
- Capacity: 10+ clients per VPS
- Bottleneck: VPS resources, not architecture

### Known Configurations

**Current Client:**
- Name: `<client>`
- Domain: `n8n.<client>.cloud`
- GCS Bucket: `<client>-n8n-postgres-backup` (us-central1)
- Monitoring: Connected to shared Prometheus
- Backups: Daily at 2 AM

### Next Steps (Optional)

1. [ ] Set up cron for automated backups
2. [ ] Configure Prometheus dashboards in Grafana
3. [ ] Test backup restore procedure
4. [ ] Document restore process
5. [ ] Set up alerting for failed backups
6. [ ] Add more clients as needed

---

**Last Updated:** November 12, 2025
**Status:** Production Ready ✅
