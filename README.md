# Stealth Multiplex Tunnel Xray / تونل استیل چندگانه Xray

[![English](https://img.shields.io/badge/Language-English-blue.svg)](README.md)
[![Persian](https://img.shields.io/badge/زبان-فارسی-green.svg)](#فارسی)

---

## English

A production-ready, stealth tunnel solution supporting multiple protocols (VLESS/Trojan) and security options (TLS/Reality) with multi-port support and interactive configuration.

### 🚀 Features

- **Multi-Protocol Support**: VLESS and Trojan protocols
- **Multi-Security Options**: TLS and Reality security
- **Multi-Port Support**: Dynamic port management
- **Interactive Installation**: User-friendly setup process
- **Production Ready**: Comprehensive monitoring and management tools
- **Stealth Features**: Decoy sites, hidden tunnels, Chrome fingerprinting
- **Enhanced Reality**: Multiple short IDs, custom destinations
- **XHTTP Support**: Complete XHTTP configuration with socket settings
- **Multi-Hop Support**: Optional Server C for extended routing (A→B→C)

### 📋 Quick Start

```bash
# Clone the repository
git clone https://github.com/letmefind/stealth-multiplex-tunnel-xray.git
cd stealth-multiplex-tunnel-xray

# For servers with limited internet (e.g., China):
# First install Xray offline
sudo bash install_xray_offline.sh

# Then run the main installer
sudo bash install

# For servers with good internet connectivity:
sudo bash install
```

### 🏗️ Architecture

- **Server A (Entry)**: Accepts connections on multiple ports and forwards them through a stealth tunnel
- **Server B (Intermediate)**: Receives tunneled traffic from Server A and can forward to Server C or route to local services
- **Server C (Final Destination)**: Optional final destination that receives traffic from Server B and routes to local services

**Routing Modes:**
- **Direct Routing**: `Server A → Server B` (routes to local services)
- **Multi-Hop Routing**: `Server A → Server B → Server C` (optional intermediate hop)

### 📁 Project Structure

```
stealth-multiplex-tunnel-xray/
├── install                       # 🚀 Main interactive installer
├── install_xray_offline.sh      # 🌐 Offline Xray installer (China/slow networks)
├── README.md                     # 📖 Comprehensive documentation (English + Persian)
├── LICENSE                       # 📄 License file
├── DESCRIPTION.md                # 📝 Project description
├── PROJECT_SUMMARY.md            # 📊 Detailed project summary
├── scripts/
│   ├── install_a.sh            # 🔧 Server A installer
│   ├── install_b.sh            # 🔧 Server B installer
│   ├── manage_ports.sh         # 🔧 Port management utility
│   ├── backup_config.sh        # 🔧 Configuration backup utility
│   ├── status.sh               # 🔧 Status monitoring utility
│   ├── troubleshoot.sh         # 🔧 Comprehensive troubleshooting script
│   ├── quick_fix.sh            # 🔧 Quick fix for common issues
│   ├── resolve_xray_conflict.sh # 🔧 Xray conflict resolver
│   ├── validate_and_fix_config.sh # 🔧 Configuration validator and fixer
│   └── fix_b_to_c_keys.sh      # 🔧 B->C connection key fixer
├── systemd/
│   ├── xray-a.service          # ⚙️ Server A systemd service
│   ├── xray-b.service          # ⚙️ Server B systemd service
│   └── xray-c.service          # ⚙️ Server C systemd service
├── nginx/
│   └── stealth-8081.conf       # 🌐 Nginx configuration template
└── xray/
    └── templates/
        ├── a.tmpl.json         # 🛠️ Server A Xray template
        └── b.tmpl.json         # 🛠️ Server B Xray template
```

### 🔧 Installation Process

1. **Run Interactive Installer** - `sudo bash install`
2. **Choose Server Type** - Server A (Tunnel), Server B (Intermediate), or Server C (Final Destination)
3. **Configure Settings** - Follow interactive prompts
4. **Generate Keys** - Reality keys generated automatically (separate keys for A->B and B->C)
5. **Test connectivity** - Verify end-to-end functionality

### 🎯 Installation Options

- **Interactive Mode**: `sudo bash install` (recommended)
- **Auto-detect**: `sudo bash install auto`
- **Server A**: `sudo bash install a`
- **Server B**: `sudo bash install b`
- **Server C**: `sudo bash install c`

### 🔗 Multi-Hop Setup (A→B→C)

For multi-hop tunneling:

1. **Install Server A** - `sudo bash install a`
   - Configure Server B IP and tunnel port
   - Save the generated UUID, private key, and short IDs

2. **Install Server B** - `sudo bash install b`
   - Enter details from Server A
   - When asked, choose to forward to Server C
   - Enter Server C IP and tunnel port
   - Save the NEW B->C UUID, private key, and short IDs (different from A->B!)

3. **Install Server C** - `sudo bash install c`
   - Enter B->C connection details from Server B
   - Configure target port for local services
   - Server C will route traffic to local services

### ✨ Interactive Installer Features

- **Modern UI**: Beautiful, colorful interface with emojis and progress indicators
- **Step-by-step Setup**: Clear questions with explanations and default values
- **Automatic Key Generation**: Reality keys generated automatically with Xray
- **Input Validation**: IP address and port validation with helpful error messages
- **Configuration Summary**: Review all settings before installation
- **Server Type Detection**: Auto-detect server type based on installed services
- **Comprehensive Logging**: Detailed installation logs and status messages

### 🛡️ Security Features

- Chrome TLS fingerprinting
- Reality protocol support
- Decoy website serving
- Hidden tunnel paths
- Certificate management
- Firewall integration
- UUID security

### 🌐 XHTTP (SplitHTTP) Configuration

The tunnel uses XHTTP (SplitHTTP) transport for stealth communication. Here's what each configuration value means:

#### **Core Settings:**
- **`path`**: `/assets` - The HTTP path used for tunnel communication (disguised as asset requests)
- **`mode`**: `auto` - Automatic mode selection for optimal performance

#### **Performance Tuning:**
- **`scMaxEachPostBytes`**: `1000000` (1MB) - Maximum bytes per HTTP POST request
- **`scMaxConcurrentPosts`**: `6` - Maximum concurrent HTTP POST requests
- **`scMinPostsIntervalMs`**: `25` - Minimum interval between POST requests (25ms)

#### **Stealth Features:**
- **`noSSEHeader`**: `false` - Include Server-Sent Events headers (appears more legitimate)
- **`noGRPCHeader`**: `true` - Exclude gRPC headers (reduces detection)
- **`xPaddingBytes`**: `200` - Random padding bytes to vary packet sizes

#### **Connection Management:**
- **`keepaliveperiod`**: `60` - Keep-alive period in seconds for HTTP connections

#### **Why These Values Matter:**
- **Stealth**: Mimics legitimate HTTP traffic patterns
- **Performance**: Optimized for high-throughput tunneling
- **Detection Avoidance**: Varies packet sizes and timing to avoid DPI detection
- **Reliability**: Maintains stable connections with proper keep-alive settings

### 🔐 Reality Protocol Configuration

The tunnel uses Reality protocol for enhanced security and stealth. Here's what each Reality setting means:

#### **Core Reality Settings:**
- **`serverName`**: `www.accounts.accesscontrol.windows.net` - SNI (Server Name Indication) for TLS handshake
- **`publicKey`**: Generated X25519 public key for Server A outbound connections
- **`privateKey`**: Generated X25519 private key for Server B inbound connections
- **`shortIds`**: Array of 20 different short IDs (16 characters each) for client distinction

#### **Advanced Reality Settings:**
- **`fingerprint`**: `chrome` - TLS fingerprint to mimic Chrome browser
- **`spiderX`**: `/` - Path for Reality spider (Server A only)
- **`show`**: `false` - Don't show Reality handshake (Server B only)
- **`dest`**: `www.microsoft.com:443` - Destination for Reality handshake (Server B only)
- **`serverNames`**: Array containing the server name for validation

#### **Security Benefits:**
- **No Certificate Required**: Reality doesn't need real SSL certificates
- **Perfect Forward Secrecy**: Each connection uses unique keys
- **DPI Resistance**: Harder to detect than traditional TLS tunnels
- **Browser Mimicking**: Appears as legitimate browser traffic

### 📊 Management Tools

- **Port Management**: Add/remove ports dynamically
- **Configuration Backup**: Automated backup/restore
- **Configuration Validation**: Validate and fix configuration issues
- **Key Management**: Regenerate B->C connection keys if needed

### 🌐 Offline Installation (China/Slow Networks)

For servers with limited internet connectivity or in regions with restricted access to GitHub:

#### **Method 1: Automated Offline Installation**
```bash
# Download and run the offline installer
sudo bash install_xray_offline.sh

# Then run the main installer
sudo bash install
```

#### **Method 2: Manual Installation**
If the automated method fails:

1. **Download Xray manually:**
   - Go to: https://github.com/XTLS/Xray-core/releases
   - Download `Xray-linux-64.zip` (for x86_64) or appropriate architecture
   - Transfer to your server via SCP/SFTP

2. **Install manually:**
   ```bash
   # Extract and install
   unzip Xray-linux-64.zip
   sudo cp xray /usr/local/bin/
   sudo chmod +x /usr/local/bin/xray
   
   # Create service
   sudo cp install_xray_offline.sh /tmp/
   sudo bash /tmp/install_xray_offline.sh
   ```

#### **Features of Enhanced Installation:**
- ✅ **Version Detection**: Shows latest available version
- ✅ **Dual Installation Methods**: Online (recommended) + Offline (fallback)
- ✅ **Multiple Mirrors**: GitHub, ghproxy, mirror.ghproxy, fastgit
- ✅ **Architecture Detection**: Supports x86_64, ARM64, ARM32
- ✅ **Dependency Management**: Installs wget, curl, unzip automatically
- ✅ **Service Setup**: Creates systemd service and directories
- ✅ **Error Handling**: Comprehensive error messages and fallback options
- ✅ **Version Verification**: Confirms latest version installation
- ✅ **Update Notifications**: Shows when updates are available
- ✅ **Nginx Conflict Resolution**: Handles existing Nginx configurations
- ✅ **Configuration Backup**: Automatic backup of existing configurations
- ✅ **Configuration Testing**: Tests Nginx config before restart
- **Status Monitoring**: Comprehensive health checks
- **Log Analysis**: Structured logging and error tracking

### 📖 Documentation

- [README.md](README.md) - Complete installation guide
- [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) - Configuration examples
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview

### 🔧 Troubleshooting

#### **Common Issues:**

**1. Nginx Port Conflict (Server B)**
```
nginx: [emerg] duplicate default server for 0.0.0.0:80
```
**Solution:** The script automatically handles this by:
- Detecting existing Nginx configurations
- Creating backups before changes
- Disabling conflicting default sites
- Testing configuration before restart

**2. Xray Installation Failed (China/Slow Networks)**
```
Failed to download Xray binary from all mirrors
```
**Solution:** Use offline installation:
```bash
sudo bash install_xray_offline.sh
sudo bash install
```

**3. Reality Key Generation Failed**
```
Failed to parse Reality keys, using default keys
```
**Solution:** Ensure Xray is properly installed:
```bash
xray version  # Should show version
xray x25519  # Should generate keys
```

**4. Service Won't Start**
```bash
# Check service status
systemctl status xray-a  # or xray-b
systemctl status nginx

# Check logs
journalctl -u xray-a -f
journalctl -u nginx -f
```

#### **Recovery Options:**

**Restore Nginx Configuration:**
```bash
# List available backups
ls /etc/nginx/backup-*

# Restore from backup
sudo cp /etc/nginx/backup-*/default /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

**Check Installation Status:**
```bash
# Verify Xray installation
which xray
xray version

# Verify Nginx configuration
nginx -t

# Check service status
systemctl is-active xray-a xray-b xray-c nginx
```

**5. B->C Connection Issues**
```
B->C connection uses same keys as A->B (WRONG!)
```
**Solution:** Use the validation and fix scripts:
```bash
# Validate configurations
sudo bash scripts/validate_and_fix_config.sh

# Fix B->C keys if needed
sudo bash scripts/fix_b_to_c_keys.sh
```

### ⚠️ Disclaimer

This project is provided for educational and legitimate use cases only. Users are responsible for compliance with local laws and regulations.

### 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### 📞 Support

For issues and questions, please open an issue on GitHub.

---

## فارسی

یک راه‌حل تونل استیل آماده تولید که از پروتکل‌های متعدد (VLESS/Trojan) و گزینه‌های امنیتی (TLS/Reality) با پشتیبانی چندپورت و پیکربندی تعاملی پشتیبانی می‌کند.

### 🚀 ویژگی‌ها

- **پشتیبانی چندپروتکل**: پروتکل‌های VLESS و Trojan
- **گزینه‌های امنیتی متعدد**: امنیت TLS و Reality
- **پشتیبانی چندپورت**: مدیریت پویای پورت‌ها
- **نصب تعاملی**: فرآیند راه‌اندازی کاربرپسند
- **آماده تولید**: ابزارهای نظارت و مدیریت جامع
- **ویژگی‌های استیل**: سایت‌های فریب، تونل‌های مخفی، اثر انگشت Chrome
- **Reality پیشرفته**: شناسه‌های کوتاه متعدد، مقاصد سفارشی
- **پشتیبانی XHTTP**: پیکربندی کامل XHTTP با تنظیمات سوکت

### 📋 شروع سریع

```bash
# کلون کردن مخزن
git clone https://github.com/letmefind/stealth-multiplex-tunnel-xray.git
cd stealth-multiplex-tunnel-xray

# برای سرورهایی با اتصال اینترنت محدود (مثل چین):
# ابتدا Xray را آفلاین نصب کنید
sudo bash install_xray_offline.sh

# سپس نصب‌کننده اصلی را اجرا کنید
sudo bash install

# برای سرورهایی با اتصال اینترنت خوب:
sudo bash install
```

### 🏗️ معماری

- **سرور A (ورودی)**: اتصالات را روی پورت‌های متعدد می‌پذیرد و آن‌ها را از طریق تونل استیل ارسال می‌کند
- **سرور B (گیرنده)**: ترافیک تونل شده را پشت Nginx با خاتمه TLS و سایت فریب دریافت می‌کند

### 📁 ساختار پروژه

```
stealth-multiplex-tunnel-xray/
├── install                       # 🚀 نصب‌کننده تعاملی اصلی
├── install_xray_offline.sh      # 🌐 نصب‌کننده آفلاین Xray (چین/شبکه‌های کند)
├── README.md                     # 📖 مستندات جامع (انگلیسی + فارسی)
├── LICENSE                       # 📄 فایل مجوز
├── DESCRIPTION.md                # 📝 توضیحات پروژه
├── PROJECT_SUMMARY.md            # 📊 خلاصه تفصیلی پروژه
├── scripts/
│   ├── install_a.sh            # 🔧 نصب‌کننده سرور A
│   ├── install_b.sh            # 🔧 نصب‌کننده سرور B
│   ├── manage_ports.sh         # 🔧 ابزار مدیریت پورت
│   ├── backup_config.sh        # 🔧 ابزار پشتیبان‌گیری پیکربندی
│   ├── status.sh               # 🔧 ابزار نظارت وضعیت
│   ├── troubleshoot.sh         # 🔧 اسکریپت عیب‌یابی جامع
│   ├── quick_fix.sh            # 🔧 رفع سریع مشکلات رایج
│   └── resolve_xray_conflict.sh # 🔧 حل‌کننده تعارض Xray
├── systemd/
│   ├── xray-a.service          # ⚙️ سرویس systemd سرور A
│   └── xray-b.service          # ⚙️ سرویس systemd سرور B
├── nginx/
│   └── stealth-8081.conf       # 🌐 الگوی پیکربندی Nginx
└── xray/
    └── templates/
        ├── a.tmpl.json         # 🛠️ الگوی Xray سرور A
        └── b.tmpl.json         # 🛠️ الگوی Xray سرور B
```

### 🔧 فرآیند نصب

1. **اجرای نصب‌کننده تعاملی** - `sudo bash install`
2. **انتخاب نوع سرور** - سرور A (تونل) یا سرور B (مقصد)
3. **پیکربندی تنظیمات** - دنبال کردن دستورالعمل‌های تعاملی
4. **تولید کلیدها** - کلیدهای Reality به صورت خودکار تولید می‌شوند
5. **تست اتصال** - تأیید عملکرد end-to-end

### 🎯 گزینه‌های نصب

- **حالت تعاملی**: `sudo bash install` (توصیه شده)
- **تشخیص خودکار**: `sudo bash install auto`
- **سرور A**: `sudo bash install a`
- **سرور B**: `sudo bash install b`

### ✨ ویژگی‌های نصب‌کننده تعاملی

- **رابط کاربری مدرن**: رابط زیبا و رنگی با ایموجی و نشانگرهای پیشرفت
- **راه‌اندازی گام به گام**: سوالات واضح با توضیحات و مقادیر پیش‌فرض
- **تولید خودکار کلید**: کلیدهای Reality به صورت خودکار با Xray تولید می‌شوند
- **اعتبارسنجی ورودی**: اعتبارسنجی آدرس IP و پورت با پیام‌های خطای مفید
- **خلاصه پیکربندی**: بررسی تمام تنظیمات قبل از نصب
- **تشخیص نوع سرور**: تشخیص خودکار نوع سرور بر اساس سرویس‌های نصب شده
- **ثبت‌سازی جامع**: لاگ‌های تفصیلی نصب و پیام‌های وضعیت

### 🛡️ ویژگی‌های امنیتی

- اثر انگشت TLS Chrome
- پشتیبانی پروتکل Reality
- ارائه سایت فریب
- مسیرهای تونل مخفی
- مدیریت گواهی
- یکپارچگی فایروال
- امنیت UUID

### 🌐 پیکربندی XHTTP (SplitHTTP)

تونل از انتقال XHTTP (SplitHTTP) برای ارتباط استیل استفاده می‌کند. در اینجا معنای هر مقدار پیکربندی آمده است:

#### **تنظیمات اصلی:**
- **`path`**: `/assets` - مسیر HTTP استفاده شده برای ارتباط تونل (مخفی شده به عنوان درخواست‌های asset)
- **`mode`**: `auto` - انتخاب حالت خودکار برای عملکرد بهینه

#### **تنظیم عملکرد:**
- **`scMaxEachPostBytes`**: `1000000` (1MB) - حداکثر بایت در هر درخواست HTTP POST
- **`scMaxConcurrentPosts`**: `6` - حداکثر درخواست‌های HTTP POST همزمان
- **`scMinPostsIntervalMs`**: `25` - حداقل فاصله بین درخواست‌های POST (25ms)

#### **ویژگی‌های استیل:**
- **`noSSEHeader`**: `false` - شامل کردن هدرهای Server-Sent Events (قانونی‌تر به نظر می‌رسد)
- **`noGRPCHeader`**: `true` - حذف هدرهای gRPC (کاهش تشخیص)
- **`xPaddingBytes`**: `200` - بایت‌های padding تصادفی برای تغییر اندازه بسته‌ها

#### **مدیریت اتصال:**
- **`keepaliveperiod`**: `60` - دوره keep-alive در ثانیه برای اتصالات HTTP

#### **چرا این مقادیر مهم هستند:**
- **استیل**: الگوهای ترافیک HTTP قانونی را تقلید می‌کند
- **عملکرد**: برای تونل‌زنی با توان بالا بهینه شده
- **اجتناب از تشخیص**: اندازه بسته‌ها و زمان‌بندی را تغییر می‌دهد تا از تشخیص DPI اجتناب کند
- **قابلیت اطمینان**: اتصالات پایدار را با تنظیمات keep-alive مناسب حفظ می‌کند

### 🔐 پیکربندی پروتکل Reality

تونل از پروتکل Reality برای امنیت و استیل پیشرفته استفاده می‌کند. در اینجا معنای هر تنظیم Reality آمده است:

#### **تنظیمات اصلی Reality:**
- **`serverName`**: `www.accounts.accesscontrol.windows.net` - SNI (Server Name Indication) برای TLS handshake
- **`publicKey`**: کلید عمومی X25519 تولید شده برای اتصالات خروجی سرور A
- **`privateKey`**: کلید خصوصی X25519 تولید شده برای اتصالات ورودی سرور B
- **`shortIds`**: آرایه‌ای از 20 شناسه کوتاه مختلف (هر کدام 16 کاراکتر) برای تمایز کلاینت

#### **تنظیمات پیشرفته Reality:**
- **`fingerprint`**: `chrome` - اثر انگشت TLS برای تقلید از مرورگر Chrome
- **`spiderX`**: `/` - مسیر برای Reality spider (فقط سرور A)
- **`show`**: `false` - نمایش ندادن Reality handshake (فقط سرور B)
- **`dest`**: `www.microsoft.com:443` - مقصد برای Reality handshake (فقط سرور B)
- **`serverNames`**: آرایه‌ای شامل نام سرور برای اعتبارسنجی

#### **مزایای امنیتی:**
- **بدون نیاز به گواهی**: Reality نیازی به گواهی‌های SSL واقعی ندارد
- **Perfect Forward Secrecy**: هر اتصال از کلیدهای منحصر به فرد استفاده می‌کند
- **مقاومت در برابر DPI**: تشخیص آن سخت‌تر از تونل‌های TLS سنتی است
- **تقلید مرورگر**: به عنوان ترافیک قانونی مرورگر ظاهر می‌شود

### 📊 ابزارهای مدیریت

- **مدیریت پورت**: افزودن/حذف پورت‌ها به صورت پویا
- **پشتیبان‌گیری پیکربندی**: پشتیبان‌گیری/بازیابی خودکار

### 🌐 نصب آفلاین (چین/شبکه‌های کند)

برای سرورهایی با اتصال اینترنت محدود یا در مناطق با دسترسی محدود به GitHub:

#### **روش 1: نصب آفلاین خودکار**
```bash
# دانلود و اجرای نصب‌کننده آفلاین
sudo bash install_xray_offline.sh

# سپس اجرای نصب‌کننده اصلی
sudo bash install
```

#### **روش 2: نصب دستی**
اگر روش خودکار شکست بخورد:

1. **دانلود دستی Xray:**
   - برو به: https://github.com/XTLS/Xray-core/releases
   - دانلود `Xray-linux-64.zip` (برای x86_64) یا معماری مناسب
   - انتقال به سرور از طریق SCP/SFTP

2. **نصب دستی:**
   ```bash
   # استخراج و نصب
   unzip Xray-linux-64.zip
   sudo cp xray /usr/local/bin/
   sudo chmod +x /usr/local/bin/xray
   
   # ایجاد سرویس
   sudo cp install_xray_offline.sh /tmp/
   sudo bash /tmp/install_xray_offline.sh
   ```

#### **ویژگی‌های نصب پیشرفته:**
- ✅ **تشخیص نسخه**: آخرین نسخه موجود را نمایش می‌دهد
- ✅ **دو روش نصب**: آنلاین (توصیه شده) + آفلاین (پشتیبان)
- ✅ **چندین آینه**: GitHub، ghproxy، mirror.ghproxy، fastgit
- ✅ **تشخیص معماری**: از x86_64، ARM64، ARM32 پشتیبانی می‌کند
- ✅ **مدیریت وابستگی‌ها**: wget، curl، unzip را خودکار نصب می‌کند
- ✅ **تنظیم سرویس**: سرویس systemd و دایرکتوری‌ها را ایجاد می‌کند
- ✅ **مدیریت خطا**: پیام‌های خطای جامع و گزینه‌های جایگزین
- ✅ **تأیید نسخه**: نصب آخرین نسخه را تأیید می‌کند
- ✅ **اطلاع‌رسانی به‌روزرسانی**: زمانی که به‌روزرسانی موجود است نمایش می‌دهد
- ✅ **حل تعارض Nginx**: مدیریت پیکربندی‌های موجود Nginx
- ✅ **پشتیبان‌گیری پیکربندی**: پشتیبان‌گیری خودکار پیکربندی‌های موجود
- ✅ **تست پیکربندی**: تست پیکربندی Nginx قبل از راه‌اندازی مجدد
- **نظارت وضعیت**: بررسی‌های سلامت جامع
- **تحلیل لاگ**: ثبت‌سازی ساختاریافته و ردیابی خطا

### 📖 مستندات

- [README.md](README.md) - راهنمای نصب کامل
- [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) - نمونه‌های پیکربندی
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - نمای کلی پروژه

### 🔧 عیب‌یابی

#### **مشکلات رایج:**

**1. تعارض پورت Nginx (سرور B)**
```
nginx: [emerg] duplicate default server for 0.0.0.0:80
```
**راه‌حل:** اسکریپت به صورت خودکار این مشکل را حل می‌کند:
- تشخیص پیکربندی‌های موجود Nginx
- ایجاد پشتیبان قبل از تغییرات
- غیرفعال کردن سایت‌های پیش‌فرض متضاد
- تست پیکربندی قبل از راه‌اندازی مجدد

**2. نصب Xray ناموفق (چین/شبکه‌های کند)**
```
Failed to download Xray binary from all mirrors
```
**راه‌حل:** از نصب آفلاین استفاده کنید:
```bash
sudo bash install_xray_offline.sh
sudo bash install
```

**3. تولید کلید Reality ناموفق**
```
Failed to parse Reality keys, using default keys
```
**راه‌حل:** اطمینان حاصل کنید که Xray به درستی نصب شده:
```bash
xray version  # باید نسخه را نشان دهد
xray x25519  # باید کلیدها را تولید کند
```

**4. سرویس راه‌اندازی نمی‌شود**
```bash
# بررسی وضعیت سرویس
systemctl status xray-a  # یا xray-b
systemctl status nginx

# بررسی لاگ‌ها
journalctl -u xray-a -f
journalctl -u nginx -f
```

#### **گزینه‌های بازیابی:**

**بازیابی پیکربندی Nginx:**
```bash
# لیست پشتیبان‌های موجود
ls /etc/nginx/backup-*

# بازیابی از پشتیبان
sudo cp /etc/nginx/backup-*/default /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

**بررسی وضعیت نصب:**
```bash
# تأیید نصب Xray
which xray
xray version

# تأیید پیکربندی Nginx
nginx -t

# بررسی وضعیت سرویس‌ها
systemctl is-active xray-a xray-b nginx
```

### ⚠️ سلب مسئولیت

این پروژه فقط برای موارد استفاده آموزشی و مشروع ارائه شده است. کاربران مسئول رعایت قوانین محلی هستند.

### 📄 مجوز

این پروژه تحت مجوز MIT مجوز دارد - برای جزئیات فایل LICENSE را ببینید.

### 🤝 مشارکت

مشارکت‌ها خوشامد است! لطفاً Pull Request ارسال کنید.

### 📞 پشتیبانی

برای مسائل و سوالات، لطفاً یک issue در GitHub باز کنید.

---

## 🌍 Language Selection / انتخاب زبان

- [English](#english) - Complete English documentation
- [فارسی](#فارسی) - مستندات کامل فارسی

## 📊 Project Stats / آمار پروژه

![GitHub stars](https://img.shields.io/github/stars/letmefind/stealth-multiplex-tunnel-xray?style=social)
![GitHub forks](https://img.shields.io/github/forks/letmefind/stealth-multiplex-tunnel-xray?style=social)
![GitHub issues](https://img.shields.io/github/issues/letmefind/stealth-multiplex-tunnel-xray)
![GitHub license](https://img.shields.io/github/license/letmefind/stealth-multiplex-tunnel-xray)

## 🔗 Quick Links / لینک‌های سریع

- **Installation Guide / راهنمای نصب**: [README.md](README.md)
- **Configuration Examples / نمونه‌های پیکربندی**: [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md)
- **Project Summary / خلاصه پروژه**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- **Issues / مسائل**: [GitHub Issues](https://github.com/letmefind/stealth-multiplex-tunnel-xray/issues)
- **Releases / انتشارات**: [GitHub Releases](https://github.com/letmefind/stealth-multiplex-tunnel-xray/releases)