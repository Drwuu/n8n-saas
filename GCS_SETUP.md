# Google Cloud Storage Backup Setup

## Prerequisites

1. **Google Cloud Project** with billing enabled
2. **GCS Bucket** for backups
3. **Service Account** with Storage permissions

## Step 1: Create GCS Bucket

```bash
# Using gcloud CLI
gcloud storage buckets create gs://YOUR-BACKUP-BUCKET-NAME \
  --location=us-central1 \
  --uniform-bucket-level-access

# Set lifecycle policy to auto-delete old backups (optional)
cat > lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 30}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://YOUR-BACKUP-BUCKET-NAME
```

## Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create n8n-backup-sa \
  --display-name="N8N Backup Service Account"

# Grant storage permissions
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="serviceAccount:n8n-backup-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Create and download key
gcloud iam service-accounts keys create ./gcs-key/service-account-key.json \
  --iam-account=n8n-backup-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com
```

## Step 3: Configure Environment

Add to your `.env` file (or client-specific env):

```bash
# Google Cloud Storage Backup Configuration
GCS_BACKUP_BUCKET=your-backup-bucket-name
```

## Step 4: Setup Directory Structure

```bash
# Create directory for GCS credentials
mkdir -p ./gcs-key

# Move service account key to the directory
mv service-account-key.json ./gcs-key/

# Secure the key file
chmod 600 ./gcs-key/service-account-key.json

# Add to .gitignore
echo "gcs-key/" >> .gitignore
```

## Step 5: Test Backup

```bash
# Run backup manually
docker compose --profile backup up postgres-backup

# Check GCS bucket
gsutil ls gs://YOUR-BACKUP-BUCKET-NAME/n8n-backups/
```

## Setup Automated Backups

### Option 1: Cron Job (Simple)

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /home/ubuntu/kizunai-n8n && docker compose --profile backup up postgres-backup >> /var/log/n8n-backup.log 2>&1
```

### Option 2: Systemd Timer (Recommended)

Create `/etc/systemd/system/n8n-backup.service`:
```ini
[Unit]
Description=N8N PostgreSQL Backup
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/home/ubuntu/kizunai-n8n
ExecStart=/usr/bin/docker compose --profile backup up postgres-backup
User=ubuntu
```

Create `/etc/systemd/system/n8n-backup.timer`:
```ini
[Unit]
Description=Daily N8N Backup Timer

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable n8n-backup.timer
sudo systemctl start n8n-backup.timer

# Check status
sudo systemctl status n8n-backup.timer
```

## Restore from Backup

### List available backups:
```bash
gsutil ls gs://YOUR-BACKUP-BUCKET-NAME/n8n-backups/${CLIENT_NAME}/
```

### Download backup:
```bash
gsutil cp gs://YOUR-BACKUP-BUCKET-NAME/n8n-backups/${CLIENT_NAME}/backup-client1-20251111-020000.dump ./restore.dump
```

### Restore to database:
```bash
# Stop n8n to prevent conflicts
docker compose stop n8n

# Restore database
docker compose exec postgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c /backups/restore.dump

# Or from host
docker compose exec -T postgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c < ./restore.dump

# Start n8n
docker compose start n8n
```

## Monitoring

### Check backup logs:
```bash
docker compose logs postgres-backup
```

### Verify GCS uploads:
```bash
gsutil ls -lh gs://YOUR-BACKUP-BUCKET-NAME/n8n-backups/${CLIENT_NAME}/
```

### Setup alerts (optional):
- Enable GCS bucket monitoring in Google Cloud Console
- Set up Cloud Monitoring alerts for upload failures
- Configure notifications via email/Slack

## Cost Estimation

**Example for 10 clients:**
- Database size: 500MB each
- Compressed backup: ~50MB each
- Storage: 10 clients × 50MB × 30 days retention = 15GB
- **Cost**: ~$0.35/month (GCS Standard Storage in us-central1)

**Transfer costs:**
- Uploads: Free
- Downloads: $0.12/GB (only when restoring)

## Security Best Practices

1. ✅ Service account key stored outside repository
2. ✅ Key file permissions set to 600
3. ✅ Principle of least privilege (Storage Object Admin only)
4. ✅ Bucket access logging enabled (optional)
5. ⚠️ Consider encrypting backups with GPG before upload
6. ⚠️ Rotate service account keys every 90 days

## Troubleshooting

**Authentication fails:**
```bash
# Verify service account key
cat ./gcs-key/service-account-key.json | jq .

# Test authentication manually
docker run --rm -v $(pwd)/gcs-key:/gcs-key \
  google/cloud-sdk:alpine \
  gcloud auth activate-service-account --key-file=/gcs-key/service-account-key.json
```

**Upload fails:**
```bash
# Check bucket permissions
gsutil iam get gs://YOUR-BACKUP-BUCKET-NAME

# Test manual upload
gsutil cp test.txt gs://YOUR-BACKUP-BUCKET-NAME/test.txt
```
