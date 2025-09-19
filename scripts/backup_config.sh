#!/bin/bash

# Stealth Multiplex Tunnel Xray - Configuration Backup Script
# Creates backups of configuration files and provides restore functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/opt/stealth-tunnel-backup"
XRAY_CONF_DIR="/etc/xray"
NGINX_CONF_DIR="/etc/nginx/conf.d"
SYSTEMD_DIR="/etc/systemd/system"
RETENTION_DAYS=30

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
}

# Create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/backup_$timestamp"
    
    log_info "Creating backup: $backup_path"
    
    mkdir -p "$backup_path"
    
    # Backup Xray configurations
    if [[ -d "$XRAY_CONF_DIR" ]]; then
        cp -r "$XRAY_CONF_DIR" "$backup_path/"
        log_info "Xray configurations backed up"
    fi
    
    # Backup Nginx configurations
    if [[ -d "$NGINX_CONF_DIR" ]]; then
        cp -r "$NGINX_CONF_DIR" "$backup_path/"
        log_info "Nginx configurations backed up"
    fi
    
    # Backup systemd services
    if [[ -f "$SYSTEMD_DIR/xray-a.service" ]]; then
        cp "$SYSTEMD_DIR/xray-a.service" "$backup_path/"
        log_info "Xray-A service backed up"
    fi
    
    if [[ -f "$SYSTEMD_DIR/xray-b.service" ]]; then
        cp "$SYSTEMD_DIR/xray-b.service" "$backup_path/"
        log_info "Xray-B service backed up"
    fi
    
    # Create backup info file
    cat > "$backup_path/backup_info.txt" << EOF
Backup created: $(date)
Backup path: $backup_path
System: $(uname -a)
Xray version: $(xray version 2>/dev/null || echo "Not installed")
Nginx version: $(nginx -v 2>&1 || echo "Not installed")
EOF
    
    log_success "Backup created successfully: $backup_path"
}

# List backups
list_backups() {
    log_info "Available backups:"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warning "No backup directory found"
        return 0
    fi
    
    local backups=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup_*" | sort -r)
    
    if [[ -z "$backups" ]]; then
        log_warning "No backups found"
        return 0
    fi
    
    echo "$backups" | while read -r backup; do
        if [[ -n "$backup" ]]; then
            local backup_name=$(basename "$backup")
            local backup_date=$(echo "$backup_name" | sed 's/backup_//')
            local backup_size=$(du -sh "$backup" | cut -f1)
            echo "  $backup_name ($backup_size) - $backup_date"
        fi
    done
}

# Restore backup
restore_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup not found: $backup_path"
        exit 1
    fi
    
    log_warning "This will overwrite current configurations!"
    read -p "Are you sure you want to restore from $backup_name? [y/N]: " CONFIRM
    
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    log_info "Restoring from backup: $backup_path"
    
    # Stop services
    systemctl stop xray-a xray-b nginx || true
    
    # Restore Xray configurations
    if [[ -d "$backup_path/xray" ]]; then
        cp -r "$backup_path/xray"/* "$XRAY_CONF_DIR/"
        log_info "Xray configurations restored"
    fi
    
    # Restore Nginx configurations
    if [[ -d "$backup_path/conf.d" ]]; then
        cp -r "$backup_path/conf.d"/* "$NGINX_CONF_DIR/"
        log_info "Nginx configurations restored"
    fi
    
    # Restore systemd services
    if [[ -f "$backup_path/xray-a.service" ]]; then
        cp "$backup_path/xray-a.service" "$SYSTEMD_DIR/"
        log_info "Xray-A service restored"
    fi
    
    if [[ -f "$backup_path/xray-b.service" ]]; then
        cp "$backup_path/xray-b.service" "$SYSTEMD_DIR/"
        log_info "Xray-B service restored"
    fi
    
    # Reload systemd and restart services
    systemctl daemon-reload
    systemctl start nginx xray-a xray-b
    
    log_success "Backup restored successfully"
}

# Clean old backups
clean_backups() {
    log_info "Cleaning backups older than $RETENTION_DAYS days..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warning "No backup directory found"
        return 0
    fi
    
    local old_backups=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup_*" -mtime +$RETENTION_DAYS)
    
    if [[ -z "$old_backups" ]]; then
        log_info "No old backups to clean"
        return 0
    fi
    
    echo "$old_backups" | while read -r backup; do
        if [[ -n "$backup" ]]; then
            log_info "Removing old backup: $(basename "$backup")"
            rm -rf "$backup"
        fi
    done
    
    log_success "Old backups cleaned"
}

# Show usage
show_usage() {
    echo "Usage: $0 <command> [backup_name]"
    echo
    echo "Commands:"
    echo "  create          Create a new backup"
    echo "  list            List available backups"
    echo "  restore <name>  Restore from a backup"
    echo "  clean           Clean old backups"
    echo "  help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 create"
    echo "  $0 list"
    echo "  $0 restore backup_20231201_120000"
    echo "  $0 clean"
    echo
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "create")
            check_root
            create_backup_dir
            create_backup
            ;;
        "list")
            check_root
            list_backups
            ;;
        "restore")
            if [[ $# -ne 2 ]]; then
                log_error "Backup name required for restore command"
                show_usage
                exit 1
            fi
            
            check_root
            restore_backup "$2"
            ;;
        "clean")
            check_root
            clean_backups
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
