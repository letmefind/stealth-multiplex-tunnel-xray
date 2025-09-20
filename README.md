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

### 📋 Quick Start

```bash
# Clone the repository
git clone https://github.com/letmefind/stealth-multiplex-tunnel-xray.git
cd stealth-multiplex-tunnel-xray

# Run the interactive installer
sudo bash install
```

### 🏗️ Architecture

- **Server A (Entry)**: Accepts connections on multiple ports and forwards them through a stealth tunnel
- **Server B (Receiver)**: Receives tunneled traffic behind Nginx with TLS termination and decoy site

### 📁 Project Structure

```
stealth-multiplex-tunnel-xray/
├── install                       # 🚀 Main interactive installer
├── README.md                     # 📖 Comprehensive documentation
├── README_FA.md                  # 📖 Persian documentation
├── LICENSE                       # 📄 License file
├── CONFIGURATION_EXAMPLES.md     # 📋 Configuration examples
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
│   └── resolve_xray_conflict.sh # 🔧 Xray conflict resolver
├── systemd/
│   ├── xray-a.service          # ⚙️ Server A systemd service
│   └── xray-b.service          # ⚙️ Server B systemd service
├── nginx/
│   └── stealth-8081.conf       # 🌐 Nginx configuration template
└── xray/
    └── templates/
        ├── a.tmpl.json         # 🛠️ Server A Xray template
        └── b.tmpl.json         # 🛠️ Server B Xray template
```

### 🔧 Installation Process

1. **Run Interactive Installer** - `sudo bash install`
2. **Choose Server Type** - Server A (Tunnel) or Server B (Destination)
3. **Configure Settings** - Follow interactive prompts
4. **Generate Keys** - Reality keys generated automatically
5. **Test connectivity** - Verify end-to-end functionality

### 🎯 Installation Options

- **Interactive Mode**: `sudo bash install` (recommended)
- **Auto-detect**: `sudo bash install auto`
- **Server A**: `sudo bash install a`
- **Server B**: `sudo bash install b`

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

### 📊 Management Tools

- **Port Management**: Add/remove ports dynamically
- **Configuration Backup**: Automated backup/restore
- **Status Monitoring**: Comprehensive health checks
- **Log Analysis**: Structured logging and error tracking

### 📖 Documentation

- [README.md](README.md) - Complete installation guide
- [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) - Configuration examples
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview

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

# اجرای نصب‌کننده تعاملی
sudo bash install
```

### 🏗️ معماری

- **سرور A (ورودی)**: اتصالات را روی پورت‌های متعدد می‌پذیرد و آن‌ها را از طریق تونل استیل ارسال می‌کند
- **سرور B (گیرنده)**: ترافیک تونل شده را پشت Nginx با خاتمه TLS و سایت فریب دریافت می‌کند

### 📁 ساختار پروژه

```
stealth-multiplex-tunnel-xray/
├── install                       # 🚀 نصب‌کننده تعاملی اصلی
├── README.md                     # 📖 مستندات جامع
├── README_FA.md                  # 📖 مستندات فارسی
├── LICENSE                       # 📄 فایل مجوز
├── CONFIGURATION_EXAMPLES.md     # 📋 نمونه‌های پیکربندی
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

### 📊 ابزارهای مدیریت

- **مدیریت پورت**: افزودن/حذف پورت‌ها به صورت پویا
- **پشتیبان‌گیری پیکربندی**: پشتیبان‌گیری/بازیابی خودکار
- **نظارت وضعیت**: بررسی‌های سلامت جامع
- **تحلیل لاگ**: ثبت‌سازی ساختاریافته و ردیابی خطا

### 📖 مستندات

- [README.md](README.md) - راهنمای نصب کامل
- [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md) - نمونه‌های پیکربندی
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - نمای کلی پروژه

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