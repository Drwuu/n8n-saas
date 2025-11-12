#!/bin/bash
#
# N8N PostgreSQL Backup Script with GCS Upload
# Runs backup for all client instances
#
# Usage:
#   ./backup-all.sh [options]
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#
# Features:
#   - Backs up all client databases to local ./backups/
#   - Uploads compressed dumps to Google Cloud Storage
#   - Cleans up old local backups (7 days)
#   - Removes old GCS backups (configured per bucket)
#
# Automated Setup:
#   Add to crontab: 0 2 * * * /home/ubuntu/kizunai-n8n/backup-all.sh >> /var/log/n8n-backups.log 2>&1
#
# Prerequisites:
#   - GCS service account key in ./gcs-key/service-account-key.json
#   - GCS_BACKUP_BUCKET configured in .env.<client-name>
#   - Docker and docker compose installed
#

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
VERBOSE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "N8N PostgreSQL Backup Script with GCS Upload"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo "  -v, --verbose  Enable verbose output"
            echo ""
            echo "Description:"
            echo "  Automatically backs up all n8n client databases and uploads to GCS"
            echo ""
            echo "Examples:"
            echo "  $0              # Run backup for all clients"
            echo "  $0 --verbose    # Run with detailed logging"
            echo ""
            echo "Setup automated backups:"
            echo "  crontab -e"
            echo "  Add: 0 2 * * * $PWD/$0 >> /var/log/n8n-backups.log 2>&1"
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== N8N Backup Script Started ===${NC}"
echo "Time: $(date)"
echo ""

# Function to backup a single client
backup_client() {
    local client_dir=$1
    local client_name=$(basename "$client_dir")
    
    echo -e "${YELLOW}Backing up: ${client_name}${NC}"
    
    cd "$client_dir"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.base.yml" ]; then
        echo -e "${RED}ERROR: docker-compose.base.yml not found in $client_dir${NC}"
        return 1
    fi
    
    # Run backup with profile
    if docker compose --profile backup up postgres-backup 2>&1; then
        echo -e "${GREEN}✓ Backup successful for ${client_name}${NC}"
        return 0
    else
        echo -e "${RED}✗ Backup failed for ${client_name}${NC}"
        return 1
    fi
}

[[ $VERBOSE -eq 1 ]] && echo -e "${YELLOW}Verbose mode enabled${NC}"

# Backup current directory (kizunai-n8n)
CURRENT_DIR="/home/ubuntu/kizunai-n8n"
if [ -d "$CURRENT_DIR" ]; then
    backup_client "$CURRENT_DIR"
else
    echo -e "${RED}ERROR: $CURRENT_DIR not found${NC}"
fi

# TODO: Add more clients here as they are created
# Example:
# backup_client "/home/ubuntu/client2-n8n"
# backup_client "/home/ubuntu/client3-n8n"

echo ""
echo -e "${GREEN}=== Backup Script Completed ===${NC}"
echo "Time: $(date)"
