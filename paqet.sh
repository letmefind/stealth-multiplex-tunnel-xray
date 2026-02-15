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

# Function to find optimal MTU for tunnel (embedded in script - internal use only)
find_optimal_mtu_embedded() {
    local target_host="${1:-8.8.8.8}"
    local start_mtu="${2:-1500}"
    local min_mtu="${3:-1280}"
    local optimal_mtu=1350  # Default for tunnel
    
    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
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
            break
        fi
    done
    
    # If no optimal found in tunnel range, try binary search
    if [ "$found_optimal" = false ]; then
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
        
        if [ $best_mtu -le $min_mtu ]; then
            optimal_mtu=1350  # Use default
        fi
    fi
    
    echo "$optimal_mtu"
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

# MTU Discovery Function - تمام کارایی در داخل همین تابع (بدون نیاز به فایل خارجی)
find_optimal_mtu() {
 print_header
 print_separator
 if [ "$LANG_SELECTED" == "en" ]; then
 echo -e "${BOLD}🔍 Find Optimal MTU${NC}"
 else
 echo -e "${BOLD}🔍 یافتن MTU بهینه${NC}"
 fi
 print_separator
 echo ""
 
 if [ "$LANG_SELECTED" == "en" ]; then
 print_info "Running MTU discovery tool..."
 echo ""
 print_info "This will test different MTU values to find the optimal one."
 print_info "The recommended MTU will be displayed for use in tunnel configuration."
 echo ""
 else
 print_info "اجرای ابزار یافتن MTU..."
 echo ""
 print_info "این ابزار مقادیر مختلف MTU را تست می‌کند تا بهینه‌ترین را پیدا کند."
 print_info "MTU پیشنهادی برای استفاده در کانفیگ تونل نمایش داده می‌شود."
 echo ""
 fi
 
 # Use the embedded find_optimal_mtu function directly (no external file needed)
 # Note: This function is defined at the top of the script
 local target_host="8.8.8.8"
 local optimal_mtu_result
 
 # Call the embedded function (defined at line 76)
 optimal_mtu_result=$(find_optimal_mtu_embedded "$target_host")
 
 echo ""
 print_separator
 echo ""
 
 if [ -n "$optimal_mtu_result" ] && [ "$optimal_mtu_result" -gt 0 ] 2>/dev/null; then
 if [ "$LANG_SELECTED" == "en" ]; then
 print_success "MTU discovery completed!"
 echo ""
 print_success "Optimal MTU: ${BOLD}$optimal_mtu_result${NC}"
 print_info "You can now use this MTU value when setting up tunnels."
 print_info "The default MTU in this script is set to 1350 for tunnels."
 else
 print_success "یافتن MTU به پایان رسید!"
 echo ""
 print_success "MTU بهینه: ${BOLD}$optimal_mtu_result${NC}"
 print_info "اکنون می‌توانید از این مقدار MTU هنگام راه‌اندازی تونل‌ها استفاده کنید."
 print_info "MTU پیش‌فرض در این اسکریپت برای تونل‌ها روی 1350 تنظیم شده است."
 fi
 else
 if [ "$LANG_SELECTED" == "en" ]; then
 print_warning "MTU discovery completed with warnings"
 print_info "Using default MTU: 1350"
 else
 print_warning "یافتن MTU با هشدار به پایان رسید"
 print_info "استفاده از MTU پیش‌فرض: 1350"
 fi
 optimal_mtu_result=1350
 fi
 
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
 find_optimal_mtu
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

# Main function
main() {
 # Select language first
 select_language
 
 # Check root
 check_root
 
 # Show main menu
 main_menu
}

# Run main function
main "$@"
