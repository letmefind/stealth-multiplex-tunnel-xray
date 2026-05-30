# تونل Stealth Multiplex (Xray)

نصب‌کنندهٔ تعاملی تونل **VLESS** با [Xray-core](https://github.com/XTLS/Xray-core): چند پورت روی **سرور A** (ورودی) و inbound متناظر روی **سرور B** (مقصد). در صورت نیاز، **سرور M** برای مسیر **A → M → B**.

## شروع سریع

روی هر سرور (با root):

```bash
curl -fsSL https://raw.githubusercontent.com/letmefind/stealth-multiplex-tunnel-xray/main/server.sh -o server.sh
chmod +x server.sh
sudo bash server.sh
```

`server.sh` آخرین `install` را از گیت‌هاب می‌گیرد و اجرا می‌کند (از فایل خراب محلی جلوگیری می‌کند).

یا:

```bash
sudo bash install
```

نمونهٔ خط فرمان:

```bash
sudo bash install xray b
sudo bash install xray middle b
sudo bash install xray m
sudo bash install xray a
```

## توپولوژی

| حالت | مسیر | ترتیب نصب |
|------|------|-----------|
| **مستقیم** (پیش‌فرض) | A → B | اول B، بعد A |
| **رله میانی** | A → M → B | B → M → A |

پروتکل و transport روی همهٔ hopها یکسان باشد.

**UUID (دو پای جدا — نباید یکی باشند):**

| پای | تولید | باید برابر باشد |
|-----|--------|------------------|
| **M → B** | نصب سرور B | UUID نصب B = outbound سرور M |
| **A → M** | نصب سرور M | UUID نصب M = outbound سرور A |

روی **سرور A** (حالت middle) UUID و کلید عمومی Reality را از خروجی **نصب M** وارد کنید — UUID مربوط به B را وارد نکنید.

## پروتکل‌های transport

| # | پروتکل |
|---|--------|
| 1 | XHTTP + Reality |
| 2 | XHTTP |
| 3 | TCP خام |
| 4 | TCP + Reality |
| 5 | WebSocket |
| 6 | gRPC |
| 7 | KCP (mKCP) — پیش‌فرض: MTU 1350، TTI 20ms، uplink/downlink 500، congestion روشن، بافر 32MB، پورت تونل 2053 |

## مسیرها و سرویس‌ها

- پیکربندی: `/etc/xray/` (`a.json`, `b.json`, `m.json`)
- سرویس‌ها: `xray-a`, `xray-b`, `xray-m`
- لاگ: `/var/log/xray/`

## اسکریپت‌های کمکی

```bash
sudo bash scripts/status.sh quick
sudo bash scripts/troubleshoot.sh
sudo bash scripts/manage_ports.sh list
sudo bash scripts/apply_bbr_tcp_optimization.sh
```

## عیب‌یابی

1. نصب مجدد با `server.sh`
2. `systemctl status xray-a` (یا b / m)
3. `journalctl -u xray-a -n 50`
4. `scripts/troubleshoot.sh`

اگر خروجی ترمینال کاراکترهای عجیب (`\E[?12` و مشابه) داشت، فایل محلی `install` خراب است — از `server.sh` استفاده کنید.

## مستندات انگلیسی

[README.md](README.md)

## مجوز

MIT — [LICENSE](LICENSE)
