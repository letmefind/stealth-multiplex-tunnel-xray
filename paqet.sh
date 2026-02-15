#!/bin/bash

# Paqet - Unified Management Script / اسکریپت مدیریتی یکپارچه
# Bilingual: English & Persian / دو زبانه: انگلیسی و فارسی
# Enhanced with embedded find_optimal_mtu function

# غیرفعال کردن set -e برای جلوگیری از خروج زودهنگام در دستورات تعاملی
# set -e

export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

# رنگ‌ها و نمادها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# نمادها
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"
ARROW="${CYAN}→${NC}"

# متغیرهای سراسری
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAQET_BINARY=""
CONFIG_DIR="/etc/paqet"
SERVICE_DIR="/etc/systemd/system"
PACKAGE_DIR="/root/paqet-packages"
LANG_SELECTED=""

# متغیرهای زبان - فارسی
declare -A MSG_FA
MSG_FA[title]="Paqet Manager - مدیریت یکپارچه"
MSG_FA[menu_title]="منوی اصلی"
MSG_FA[setup_server]="راه‌اندازی سرور خارج"
MSG_FA[setup_client]="راه‌اندازی کلاینت ایران"
MSG_FA[manage_configs]="مدیریت کانفیگ‌ها"
MSG_FA[manage_services]="مدیریت سرویس‌ها"
MSG_FA[mtu_discovery]="یافتن MTU بهینه"
MSG_FA[exit]="خروج"
MSG_FA[paqet_installed]="Paqet نصب شده است"
MSG_FA[paqet_not_installed]="Paqet نصب نشده است (خودکار نصب می‌شود)"
MSG_FA[select_lang]="انتخاب زبان / Select Language"
MSG_FA[lang_fa]="فارسی (Persian)"
MSG_FA[lang_en]="English"
MSG_FA[invalid_choice]="انتخاب نامعتبر"
MSG_FA[press_enter]="برای ادامه Enter را فشار دهید"
MSG_FA[goodbye]="خداحافظ! 👋"

# متغیرهای زبان - انگلیسی
declare -A MSG_EN
MSG_EN[title]="Paqet Manager - Unified Management"
MSG_EN[menu_title]="Main Menu"
MSG_EN[setup_server]="Setup Foreign Server"
MSG_EN[setup_client]="Setup Iran Client"
MSG_EN[manage_configs]="Manage Configs"
MSG_EN[manage_services]="Manage Services"
MSG_EN[mtu_discovery]="Find Optimal MTU"
MSG_EN[exit]="Exit"
MSG_EN[paqet_installed]="Paqet is installed"
MSG_EN[paqet_not_installed]="Paqet is not installed (will auto-install)"
MSG_EN[select_lang]="Select Language / انتخاب زبان"
MSG_EN[lang_fa]="Persian (فارسی)"
MSG_EN[lang_en]="English"
MSG_EN[invalid_choice]="Invalid choice"
MSG_EN[press_enter]="Press Enter to continue"
MSG_EN[goodbye]="Goodbye! 👋"

# Function to find optimal MTU for tunnel (embedded in script)
find_optimal_mtu() {
    local target_host="${1:-8.8.8.8}"
    local start_mtu="${2:-1500}"
    local min_mtu="${3:-1280}"
    local optimal_mtu=1350  # Default for tunnel
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Finding optimal MTU (testing against $target_host)..."
        print_info "This may take a moment..."
    else
        print_info "در حال یافتن MTU بهینه (تست با $target_host)..."
        print_info "این ممکن است کمی زمان ببرد..."
    fi
    
    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "ping command not found, using default MTU: $optimal_mtu"
        else
            print_warning "دستور ping پیدا نشد، استفاده از MTU پیش‌فرض: $optimal_mtu"
        fi
        echo "$optimal_mtu"
        return 0
    fi
    
    # Test MTU values from start_mtu down to min_mtu
    local found_optimal=false
    
    # For tunnel, we typically want MTU around 1350-1400
    # So we'll test common tunnel MTU values first
    local tunnel_mtus=(1500 1450 1400 1350 1300 1280)
    
    for mtu in "${tunnel_mtus[@]}"; do
        # Calculate packet size (MTU - IP header - ICMP header = MTU - 28)
        local packet_size=$((mtu - 28))
        
        if [ $packet_size -lt 0 ]; then
            continue
        fi
        
        # Test with ping (don't fragment flag)
        if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
            optimal_mtu=$mtu
            found_optimal=true
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Found working MTU: $optimal_mtu"
            else
                print_success "MTU کارآمد پیدا شد: $optimal_mtu"
            fi
            break
        fi
    done
    
    # If no optimal found in tunnel range, try binary search
    if [ "$found_optimal" = false ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_info "Testing MTU range..."
        else
            print_info "در حال تست محدوده MTU..."
        fi
        local low=$min_mtu
        local high=$start_mtu
        local best_mtu=$min_mtu
        
        while [ $low -le $high ]; do
            local mid=$(( (low + high) / 2 ))
            local packet_size=$((mid - 28))
            
            if [ $packet_size -lt 0 ]; then
                low=$((mid + 1))
                continue
            fi
            
            if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
                best_mtu=$mid
                optimal_mtu=$mid
                low=$((mid + 1))
            else
                high=$((mid - 1))
            fi
        done
        
        if [ $best_mtu -gt $min_mtu ]; then
            optimal_mtu=$best_mtu
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Found optimal MTU: $optimal_mtu"
            else
                print_success "MTU بهینه پیدا شد: $optimal_mtu"
            fi
        else
            if [ "$LANG_SELECTED" == "en" ]; then
                print_warning "Could not determine optimal MTU, using default: $optimal_mtu"
            else
                print_warning "نمی‌توان MTU بهینه را تعیین کرد، استفاده از پیش‌فرض: $optimal_mtu"
            fi
        fi
    fi
    
    echo "$optimal_mtu"
}

# Create /root/find_optimal_mtu.sh script for compatibility
create_find_optimal_mtu_script() {
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Creating find_optimal_mtu.sh script..."
    else
        print_info "در حال ایجاد اسکریپت find_optimal_mtu.sh..."
    fi
    
    cat > /root/find_optimal_mtu.sh << 'MTU_SCRIPT_EOF'
#!/bin/bash

# Find Optimal MTU Script
# Embedded in paqet.sh - no need to download separately

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to find optimal MTU for tunnel
find_optimal_mtu() {
    local target_host="${1:-8.8.8.8}"
    local start_mtu="${2:-1500}"
    local min_mtu="${3:-1280}"
    local optimal_mtu=1350  # Default for tunnel
    
    log_info "Finding optimal MTU (testing against $target_host)..."
    log_info "This may take a moment..."
    
    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
        log_warning "ping command not found, using default MTU: $optimal_mtu"
        echo "$optimal_mtu"
        return 0
    fi
    
    # Test MTU values from start_mtu down to min_mtu
    local found_optimal=false
    
    # For tunnel, we typically want MTU around 1350-1400
    # So we'll test common tunnel MTU values first
    local tunnel_mtus=(1500 1450 1400 1350 1300 1280)
    
    for mtu in "${tunnel_mtus[@]}"; do
        # Calculate packet size (MTU - IP header - ICMP header = MTU - 28)
        local packet_size=$((mtu - 28))
        
        if [ $packet_size -lt 0 ]; then
            continue
        fi
        
        # Test with ping (don't fragment flag)
        if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
            optimal_mtu=$mtu
            found_optimal=true
            log_success "Found working MTU: $optimal_mtu"
            break
        fi
    done
    
    # If no optimal found in tunnel range, try binary search
    if [ "$found_optimal" = false ]; then
        log_info "Testing MTU range..."
        local low=$min_mtu
        local high=$start_mtu
        local best_mtu=$min_mtu
        
        while [ $low -le $high ]; do
            local mid=$(( (low + high) / 2 ))
            local packet_size=$((mid - 28))
            
            if [ $packet_size -lt 0 ]; then
                low=$((mid + 1))
                continue
            fi
            
            if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
                best_mtu=$mid
                optimal_mtu=$mid
                low=$((mid + 1))
            else
                high=$((mid - 1))
            fi
        done
        
        if [ $best_mtu -gt $min_mtu ]; then
            optimal_mtu=$best_mtu
            log_success "Found optimal MTU: $optimal_mtu"
        else
            log_warning "Could not determine optimal MTU, using default: $optimal_mtu"
        fi
    fi
    
    echo "$optimal_mtu"
}

# Main execution (if run directly, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    OPTIMAL_MTU=$(find_optimal_mtu "$@")
    echo "$OPTIMAL_MTU"
fi
MTU_SCRIPT_EOF
    
    chmod +x /root/find_optimal_mtu.sh
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Created /root/find_optimal_mtu.sh"
    else
        print_success "فایل /root/find_optimal_mtu.sh ایجاد شد"
    fi
}

# تابع انتخاب زبان
select_language() {
 clear
 echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
 echo -e "${CYAN}║${NC} ${CYAN}║${NC}"
 echo -e "${CYAN}║${NC} ${BOLD}${GREEN}Paqet Manager${NC}${BOLD} ${CYAN}║${NC}"
 echo -e "${CYAN}║${NC} ${CYAN}║${NC}"
 echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
 echo ""
 echo -e "${BOLD}Select Language / انتخاب زبان:${NC}"
 echo ""
 echo -e " ${CYAN}1${NC}) ${BOLD}فارسی${NC} (Persian)"
 echo -e " ${CYAN}2${NC}) ${BOLD}English${NC}"
 echo ""
 
 # خواندن از stdin (که در main به /dev/tty redirect شده)
 read -p "Choose / انتخاب [1/2]: " LANG_CHOICE
 
 case "$LANG_CHOICE" in
 1|fa|persian|فارسی)
 LANG_SELECTED="fa"
 ;;
 2|en|english|انگلیسی)
 LANG_SELECTED="en"
 ;;
 *)
 LANG_SELECTED="fa" # پیش‌فرض فارسی
 ;;
 esac
}

# تابع‌های ترجمه
t() {
 local key="$1"
 if [ "$LANG_SELECTED" == "en" ]; then
 echo -n "${MSG_EN[$key]}"
 else
 echo -n "${MSG_FA[$key]}"
 fi
}

# تابع خواندن ورودی از terminal واقعی
read_input() {
 local prompt="$1"
 local var_name="$2"
 local default_value="${3:-}"
 
 # همیشه از /dev/tty بخوان
 if [ -t 0 ] && [ -t 1 ]; then
 # اگر هر دو stdin و stdout terminal هستند، از stdin استفاده کن
 if [ -n "$default_value" ]; then
 read -p "$prompt [$default_value]: " "$var_name" < /dev/tty
 else
 read -p "$prompt: " "$var_name" < /dev/tty
 fi
 else
 # اگر stdin pipe است، از /dev/tty استفاده کن
 if [ -n "$default_value" ]; then
 echo -n "$prompt [$default_value]: " > /dev/tty
 read "$var_name" < /dev/tty
 else
 echo -n "$prompt: " > /dev/tty
 read "$var_name" < /dev/tty
 fi
 fi
 
 # اگر خالی بود و default وجود داشت، از default استفاده کن
 if [ -z "${!var_name}" ] && [ -n "$default_value" ]; then
 eval "$var_name=\"$default_value\""
 fi
}

# تابع‌های کمکی
print_header() {
 clear
 echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
 echo -e "${CYAN}║${NC} ${CYAN}║${NC}"
 echo -e "${CYAN}║${NC} ${BOLD}${GREEN}$(t title)${NC}${BOLD} ${CYAN}║${NC}"
 echo -e "${CYAN}║${NC} ${CYAN}║${NC}"
 echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
 echo ""
}

print_success() { echo -e "${CHECK} ${GREEN}$1${NC}"; }
print_error() { echo -e "${CROSS} ${RED}$1${NC}"; }
print_warning() { echo -e "${WARN} ${YELLOW}$1${NC}"; }
print_info() { echo -e "${INFO} ${BLUE}$1${NC}"; }
print_step() { echo -e "${ARROW} ${CYAN}$1${NC}"; }

print_separator() {
 echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_box() {
 local title="$1"
 local content="$2"
 echo -e "${CYAN}┌─${NC} ${BOLD}${title}${NC}"
 echo -e "${CYAN}│${NC} ${content}"
 echo -e "${CYAN}└${NC}"
}

check_root() {
 if [ "$EUID" -ne 0 ]; then
 if [ "$LANG_SELECTED" == "en" ]; then
 print_error "This script must be run as root"
 echo ""
 echo "Usage: ${BOLD}sudo $0${NC}"
 else
 print_error "این اسکریپت باید با دسترسی root اجرا شود"
 echo ""
 echo "استفاده: ${BOLD}sudo $0${NC}"
 fi
 exit 1
 fi
}

# MTU Discovery Function
mtu_discovery() {
 print_separator
 echo ""
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "🔍 Find Optimal MTU"
 else
 print_info "🔍 یافتن MTU بهینه"
 fi
 print_separator
 echo ""
 
 # Use embedded function directly (no need for external script)
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "Running MTU discovery using embedded function..."
 else
 print_info "در حال اجرای یافتن MTU با استفاده از تابع تعبیه شده..."
 fi
 echo ""
 
 # Run the embedded function directly
 OPTIMAL_MTU=$(find_optimal_mtu)
 
 echo ""
 if [ "$LANG_SELECTED" == "en" ]; then
 print_success "Optimal MTU: ${BOLD}$OPTIMAL_MTU${NC}"
 print_info "You can use this MTU value in your tunnel configuration"
 print_info "For Paqet tunnel, set MTU to: ${BOLD}$OPTIMAL_MTU${NC}"
 else
 print_success "MTU بهینه: ${BOLD}$OPTIMAL_MTU${NC}"
 print_info "می‌توانید از این مقدار MTU در تنظیمات تانل خود استفاده کنید"
 print_info "برای تانل Paqet، MTU را روی: ${BOLD}$OPTIMAL_MTU${NC} تنظیم کنید"
 fi
 
 # Also create /root/find_optimal_mtu.sh for compatibility with other scripts
 create_find_optimal_mtu_script
 
 echo ""
 if [ "$LANG_SELECTED" == "en" ]; then
 read -p "Press Enter to continue..." < /dev/tty
 else
 read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
 fi
}

# Main menu function (simplified version)
main_menu() {
 while true; do
 print_header
 echo -e "${BOLD}$(t menu_title)${NC}"
 echo ""
 echo -e " ${CYAN}1${NC}) $(t setup_server)"
 echo -e " ${CYAN}2${NC}) $(t setup_client)"
 echo -e " ${CYAN}3${NC}) $(t manage_configs)"
 echo -e " ${CYAN}4${NC}) $(t manage_services)"
 echo -e " ${CYAN}5${NC}) $(t mtu_discovery)"
 echo -e " ${CYAN}6${NC}) $(t exit)"
 echo ""
 
 if [ "$LANG_SELECTED" == "en" ]; then
 read -p "Choose option [1-6]: " CHOICE < /dev/tty
 else
 read -p "گزینه را انتخاب کنید [1-6]: " CHOICE < /dev/tty
 fi
 
 case "$CHOICE" in
 1)
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "Setup Foreign Server (not implemented in this version)"
 else
 print_info "راه‌اندازی سرور خارج (در این نسخه پیاده‌سازی نشده)"
 fi
 read -p "$(t press_enter)" < /dev/tty
 ;;
 2)
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "Setup Iran Client (not implemented in this version)"
 else
 print_info "راه‌اندازی کلاینت ایران (در این نسخه پیاده‌سازی نشده)"
 fi
 read -p "$(t press_enter)" < /dev/tty
 ;;
 3)
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "Manage Configs (not implemented in this version)"
 else
 print_info "مدیریت کانفیگ‌ها (در این نسخه پیاده‌سازی نشده)"
 fi
 read -p "$(t press_enter)" < /dev/tty
 ;;
 4)
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "Manage Services (not implemented in this version)"
 else
 print_info "مدیریت سرویس‌ها (در این نسخه پیاده‌سازی نشده)"
 fi
 read -p "$(t press_enter)" < /dev/tty
 ;;
 5)
 mtu_discovery
 ;;
 6)
 if [ "$LANG_SELECTED" == "en" ]; then
 echo ""
 print_info "$(t goodbye)"
 else
 echo ""
 print_info "$(t goodbye)"
 fi
 exit 0
 ;;
 *)
 if [ "$LANG_SELECTED" == "en" ]; then
 print_error "$(t invalid_choice)"
 else
 print_error "$(t invalid_choice)"
 fi
 sleep 1
 ;;
 esac
 done
}

# Create /root/find_optimal_mtu.sh script immediately (before language selection)
# This ensures it's available for any code that checks for it early
create_find_optimal_mtu_script_early() {
    # Create script silently (without language-dependent messages)
    cat > /root/find_optimal_mtu.sh << 'MTU_SCRIPT_EOF'
#!/bin/bash

# Find Optimal MTU Script
# Embedded in paqet.sh - no need to download separately

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to find optimal MTU for tunnel
find_optimal_mtu() {
    local target_host="${1:-8.8.8.8}"
    local start_mtu="${2:-1500}"
    local min_mtu="${3:-1280}"
    local optimal_mtu=1350  # Default for tunnel
    
    log_info "Finding optimal MTU (testing against $target_host)..."
    log_info "This may take a moment..."
    
    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
        log_warning "ping command not found, using default MTU: $optimal_mtu"
        echo "$optimal_mtu"
        return 0
    fi
    
    # Test MTU values from start_mtu down to min_mtu
    local found_optimal=false
    
    # For tunnel, we typically want MTU around 1350-1400
    # So we'll test common tunnel MTU values first
    local tunnel_mtus=(1500 1450 1400 1350 1300 1280)
    
    for mtu in "${tunnel_mtus[@]}"; do
        # Calculate packet size (MTU - IP header - ICMP header = MTU - 28)
        local packet_size=$((mtu - 28))
        
        if [ $packet_size -lt 0 ]; then
            continue
        fi
        
        # Test with ping (don't fragment flag)
        if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
            optimal_mtu=$mtu
            found_optimal=true
            log_success "Found working MTU: $optimal_mtu"
            break
        fi
    done
    
    # If no optimal found in tunnel range, try binary search
    if [ "$found_optimal" = false ]; then
        log_info "Testing MTU range..."
        local low=$min_mtu
        local high=$start_mtu
        local best_mtu=$min_mtu
        
        while [ $low -le $high ]; do
            local mid=$(( (low + high) / 2 ))
            local packet_size=$((mid - 28))
            
            if [ $packet_size -lt 0 ]; then
                low=$((mid + 1))
                continue
            fi
            
            if ping -c 1 -M do -s $packet_size -W 2 "$target_host" >/dev/null 2>&1; then
                best_mtu=$mid
                optimal_mtu=$mid
                low=$((mid + 1))
            else
                high=$((mid - 1))
            fi
        done
        
        if [ $best_mtu -gt $min_mtu ]; then
            optimal_mtu=$best_mtu
            log_success "Found optimal MTU: $optimal_mtu"
        else
            log_warning "Could not determine optimal MTU, using default: $optimal_mtu"
        fi
    fi
    
    echo "$optimal_mtu"
}

# Main execution (if run directly, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    OPTIMAL_MTU=$(find_optimal_mtu "$@")
    echo "$OPTIMAL_MTU"
fi
MTU_SCRIPT_EOF
    
    chmod +x /root/find_optimal_mtu.sh 2>/dev/null || true
}

# Main function
main() {
 # Create find_optimal_mtu.sh script FIRST (before anything else)
 # This ensures it's available immediately for any code that checks for it
 if [ "$EUID" -eq 0 ]; then
     create_find_optimal_mtu_script_early
 fi
 
 # Select language first
 select_language
 
 # Check root
 check_root
 
 # Create find_optimal_mtu.sh script on startup for compatibility (if not already created)
 if [ ! -f "/root/find_optimal_mtu.sh" ]; then
     create_find_optimal_mtu_script
 fi
 
 # Show main menu
 main_menu
}

# Run main function
main "$@"
