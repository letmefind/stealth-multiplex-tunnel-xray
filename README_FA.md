# تونل استیل چندگانه Xray

[![English](https://img.shields.io/badge/Language-English-blue.svg)](README.md)
[![Persian](https://img.shields.io/badge/زبان-فارسی-green.svg)](README_FA.md)

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

# اجرای نصب‌کننده یکپارچه
sudo bash install.sh
```

نصب‌کننده یکپارچه:
- از شما می‌پرسد کدام سرور را نصب می‌کنید (A یا B)
- اطلاعات تفصیلی در مورد هر نوع سرور ارائه می‌دهد
- اسکریپت نصب مناسب را اجرا می‌کند
- راهنمایی پس از نصب را نشان می‌دهد

### 🏗️ معماری

- **سرور A (ورودی)**: اتصالات را روی پورت‌های متعدد می‌پذیرد و آن‌ها را از طریق تونل استیل ارسال می‌کند
- **سرور B (گیرنده)**: ترافیک تونل شده را پشت Nginx با خاتمه TLS و سایت فریب دریافت می‌کند

### 📁 ساختار پروژه

```
stealth-multiplex-tunnel-xray/
├── install.sh                    # نصب‌کننده یکپارچه
├── README.md                     # مستندات جامع
├── README_FA.md                  # مستندات فارسی
├── .env.example                  # الگوی پیکربندی
├── .gitignore                    # قوانین نادیده‌گیری Git
├── CONFIGURATION_EXAMPLES.md     # نمونه‌های پیکربندی
├── PROJECT_SUMMARY.md            # خلاصه تفصیلی پروژه
├── scripts/
│   ├── install_a.sh            # نصب‌کننده سرور A
│   ├── install_b.sh            # نصب‌کننده سرور B
│   ├── manage_ports.sh         # ابزار مدیریت پورت
│   ├── backup_config.sh        # ابزار پشتیبان‌گیری پیکربندی
│   └── status.sh               # ابزار نظارت وضعیت
├── systemd/
│   ├── xray-a.service          # سرویس systemd سرور A
│   └── xray-b.service          # سرویس systemd سرور B
├── nginx/
│   └── stealth-8081.conf       # الگوی پیکربندی Nginx
└── xray/
    └── templates/
        ├── a.tmpl.json         # الگوی Xray سرور A
        └── b.tmpl.json         # الگوی Xray سرور B
```

### 🔧 فرآیند نصب

#### نصب مستقیم

اگر ترجیح می‌دهید نصب‌کننده‌ها را مستقیماً اجرا کنید:

#### 1. نصب سرور B (گیرنده)

```bash
# اجرای نصب‌کننده تعاملی
sudo bash scripts/install_b.sh
```

نصب‌کننده از شما می‌پرسد:
- نام سرور (دامنه شما)
- پورت TLS (پیش‌فرض: 8081)
- مسیر استیل (پیش‌فرض: /assets)
- انتخاب پروتکل (VLESS یا Trojan)
- انتخاب امنیت (TLS یا Reality)
- حالت گواهی (استفاده از موجود یا Certbot)
- UUID (در صورت عدم ارائه خودکار تولید می‌شود)
- پشتیبانی پروتکل پروکسی
- بهینه‌سازی TCP BBR
- ایجاد سایت فریب

#### 2. نصب سرور A (ورودی)

```bash
# اجرای نصب‌کننده تعاملی
sudo bash scripts/install_a.sh
```

نصب‌کننده از شما می‌پرسد:
- دامنه سرور B (باید با پیکربندی سرور B مطابقت داشته باشد)
- پورت TLS سرور B
- مسیر استیل (باید با سرور B مطابقت داشته باشد)
- انتخاب پروتکل (باید با سرور B مطابقت داشته باشد)
- انتخاب امنیت (باید با سرور B مطابقت داشته باشد)
- پورت‌های مجاز کلاینت (جدا شده با کاما، مثلاً: 80,443,8080,8443)
- UUID (باید با سرور B مطابقت داشته باشد)
- بهینه‌سازی TCP BBR

#### 3. مدیریت پورت‌ها (اختیاری)

پس از نصب، پورت‌ها را روی سرور A اضافه یا حذف کنید:

```bash
# افزودن پورت جدید
sudo bash scripts/manage_ports.sh add 8443

# حذف پورت
sudo bash scripts/manage_ports.sh remove 8080

# فهرست پورت‌های فعلی
sudo bash scripts/manage_ports.sh list
```

### 🛡️ ویژگی‌های امنیتی

#### مدیریت گواهی
- **حالت TLS**: نیاز به گواهی SSL معتبر برای دامنه
- **حالت Reality**: از تولید گواهی مبتنی بر SNI استفاده می‌کند، نیازی به گواهی واقعی نیست
- **یکپارچگی Certbot**: پشتیبانی از تمدید خودکار گواهی

#### پیکربندی فایروال
نصب‌کننده‌ها سعی می‌کنند قوانین فایروال UFW را پیکربندی کنند. برای فایروال‌های دیگر، پیکربندی دستی ممکن است مورد نیاز باشد:

```bash
# مثال قوانین iptables برای سرور A
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT

# مثال قوانین iptables برای سرور B
iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
```

#### امنیت UUID
- UUIDهای قوی و منحصر به فرد برای هر نصب تولید کنید
- برای امنیت بیشتر، UUIDها را به صورت دوره‌ای تغییر دهید
- هرگز UUIDها را در لاگ‌ها یا مستندات به اشتراک نگذارید

### 📊 ابزارهای مدیریت

#### مدیریت پورت
```bash
# افزودن پورت جدید
sudo bash scripts/manage_ports.sh add 8443

# حذف پورت
sudo bash scripts/manage_ports.sh remove 8080

# فهرست پورت‌های پیکربندی شده
sudo bash scripts/manage_ports.sh list
```

#### پشتیبان‌گیری پیکربندی
```bash
# ایجاد پشتیبان
sudo bash scripts/backup_config.sh create

# فهرست پشتیبان‌ها
sudo bash scripts/backup_config.sh list

# بازیابی از پشتیبان
sudo bash scripts/backup_config.sh restore backup_20231201_120000

# پاک کردن پشتیبان‌های قدیمی
sudo bash scripts/backup_config.sh clean
```

#### نظارت وضعیت
```bash
# گزارش وضعیت تفصیلی
sudo bash scripts/status.sh status

# بررسی سریع وضعیت
sudo bash scripts/status.sh quick

# بررسی اجزای خاص
sudo bash scripts/status.sh services
sudo bash scripts/status.sh ports
sudo bash scripts/status.sh configs
sudo bash scripts/status.sh logs
sudo bash scripts/status.sh resources
sudo bash scripts/status.sh connectivity
```

### 🧪 تست و تأیید

#### بررسی‌های سلامت سرور B

```bash
# بررسی اینکه سایت فریب قابل دسترسی است
curl -I https://your-domain.com:8081/

# بررسی اینکه مسیر تونل پاسخ می‌دهد (نباید تونل آشکار را نشان دهد)
curl -I https://your-domain.com:8081/assets

# بررسی وضعیت سرویس Xray
systemctl status xray-b

# بررسی لاگ‌ها
journalctl -u xray-b -e
```

#### بررسی‌های سلامت سرور A

```bash
# بررسی اینکه پورت‌ها در حال گوش دادن هستند
ss -tlnp | grep -E ':(80|443|8080|8443)\s'

# بررسی وضعیت سرویس
systemctl status xray-a

# بررسی لاگ‌ها
journalctl -u xray-a -e
```

#### تست End-to-End

1. سرویس تست را روی سرور B شروع کنید:
   ```bash
   # روی سرور B
   sudo nc -l 127.0.0.1 8080
   ```

2. از کلاینت به سرور A متصل شوید:
   ```bash
   # از کلاینت
   nc server-a-ip 8080
   ```

3. پیام‌ها را تایپ کنید - باید در جلسه nc سرور B ظاهر شوند.

### 🔧 عیب‌یابی

#### مسائل رایج

1. **خطاهای گواهی**: اطمینان حاصل کنید که DNS دامنه به سرور B اشاره می‌کند و گواهی معتبر است
2. **تداخل پورت**: بررسی کنید که پورت‌ها قبلاً توسط سرویس‌های دیگر استفاده نمی‌شوند
3. **مشکلات فایروال**: قوانین فایروال را برای پورت‌های مورد نیاز تأیید کنید
4. **عدم تطابق UUID**: اطمینان حاصل کنید که سرور A و B از همان UUID استفاده می‌کنند

#### تحلیل لاگ

```bash
# لاگ‌های Xray
journalctl -u xray-a -f
journalctl -u xray-b -f

# لاگ‌های Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# لاگ‌های سیستم
dmesg | grep -i xray
```

### 📖 مستندات

- [README.md](README.md) - راهنمای نصب کامل انگلیسی
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

## 🌍 انتخاب زبان

- [English](README.md) - Complete English documentation
- [فارسی](#فارسی) - مستندات کامل فارسی

## 📊 آمار پروژه

![GitHub stars](https://img.shields.io/github/stars/letmefind/stealth-multiplex-tunnel-xray?style=social)
![GitHub forks](https://img.shields.io/github/forks/letmefind/stealth-multiplex-tunnel-xray?style=social)
![GitHub issues](https://img.shields.io/github/issues/letmefind/stealth-multiplex-tunnel-xray)
![GitHub license](https://img.shields.io/github/license/letmefind/stealth-multiplex-tunnel-xray)

## 🔗 لینک‌های سریع

- **راهنمای نصب**: [README.md](README.md)
- **نمونه‌های پیکربندی**: [CONFIGURATION_EXAMPLES.md](CONFIGURATION_EXAMPLES.md)
- **خلاصه پروژه**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- **مسائل**: [GitHub Issues](https://github.com/letmefind/stealth-multiplex-tunnel-xray/issues)
- **انتشارات**: [GitHub Releases](https://github.com/letmefind/stealth-multiplex-tunnel-xray/releases)
