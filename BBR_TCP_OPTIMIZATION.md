# تنظیمات BBR و TCP Buffering

این فایل شامل دستورات برای اعمال بهینه‌سازی‌های BBR و TCP Buffering است.

## روش 1: استفاده از اسکریپت (توصیه می‌شود)

```bash
sudo bash scripts/apply_bbr_tcp_optimization.sh
```

## روش 2: اعمال دستی با sysctl

### 1. بارگذاری ماژول BBR (در صورت نیاز)

```bash
# بررسی وجود ماژول BBR
lsmod | grep tcp_bbr

# بارگذاری ماژول BBR
sudo modprobe tcp_bbr

# بررسی فعال بودن BBR
cat /proc/sys/net/ipv4/tcp_congestion_control
```

### 2. اعمال تنظیمات BBR

```bash
# تنظیم BBR به عنوان congestion control
sudo sysctl -w net.core.default_qdisc=fq
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
```

### 3. اعمال تنظیمات TCP Buffers

```bash
# TCP Buffer Optimizations
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
sudo sysctl -w net.ipv4.tcp_mem="262144 524288 1048576"

# TCP Window Scaling
sudo sysctl -w net.ipv4.tcp_window_scaling=1
sudo sysctl -w net.ipv4.tcp_timestamps=1
sudo sysctl -w net.ipv4.tcp_sack=1

# TCP Fast Open
sudo sysctl -w net.ipv4.tcp_fastopen=3

# Connection Tracking
sudo sysctl -w net.netfilter.nf_conntrack_max=1000000
sudo sysctl -w net.ipv4.netfilter.ip_conntrack_max=1000000

# Socket Options
sudo sysctl -w net.core.somaxconn=65535
sudo sysctl -w net.core.netdev_max_backlog=5000

# TCP Keepalive
sudo sysctl -w net.ipv4.tcp_keepalive_time=600
sudo sysctl -w net.ipv4.tcp_keepalive_probes=3
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=15

# TCP SYN Cookies (DDoS protection)
sudo sysctl -w net.ipv4.tcp_syncookies=1

# TCP Fin Timeout
sudo sysctl -w net.ipv4.tcp_fin_timeout=30

# TCP Tw Reuse
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

# MTU Settings for Packet Tunnel
# Default MTU for packet tunnel: 1350 (optimal for VPN/tunnel connections)
sudo sysctl -w net.ipv4.ip_no_pmtu_disc=0
sudo sysctl -w net.ipv4.tcp_mtu_probing=1
sudo sysctl -w net.ipv4.tcp_base_mss=1024
```

### 4. ایجاد فایل پایداری (برای اعمال خودکار بعد از reboot)

```bash
sudo tee /etc/sysctl.d/99-xray-optimization.conf > /dev/null << 'EOF'
# BBR Congestion Control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP Buffer Optimizations for High Bandwidth
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_mem=262144 524288 1048576

# TCP Window Scaling
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1

# TCP Fast Open
net.ipv4.tcp_fastopen=3

# Connection Tracking
net.netfilter.nf_conntrack_max=1000000
net.ipv4.netfilter.ip_conntrack_max=1000000

# Socket Options
net.core.somaxconn=65535
net.core.netdev_max_backlog=5000

# TCP Keepalive
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=15

# TCP SYN Cookies (DDoS protection)
net.ipv4.tcp_syncookies=1

# TCP Fin Timeout
net.ipv4.tcp_fin_timeout=30

# TCP Tw Reuse
net.ipv4.tcp_tw_reuse=1

# MTU Settings for Packet Tunnel
# Default MTU for packet tunnel: 1350 (optimal for VPN/tunnel connections)
# This prevents packet fragmentation and improves performance
net.ipv4.ip_no_pmtu_disc=0
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_base_mss=1024
EOF

# اعمال فایل
sudo sysctl --system
```

## بررسی تنظیمات

### بررسی BBR

```bash
# بررسی congestion control
cat /proc/sys/net/ipv4/tcp_congestion_control

# باید خروجی: bbr

# بررسی qdisc
cat /proc/sys/net/core/default_qdisc

# باید خروجی: fq
```

### بررسی TCP Buffers

```bash
# بررسی buffer های TCP
cat /proc/sys/net/core/rmem_max
cat /proc/sys/net/core/wmem_max
cat /proc/sys/net/ipv4/tcp_rmem
cat /proc/sys/net/ipv4/tcp_wmem
cat /proc/sys/net/ipv4/tcp_mem
```

### بررسی سایر تنظیمات

```bash
# Window Scaling
cat /proc/sys/net/ipv4/tcp_window_scaling

# Fast Open
cat /proc/sys/net/ipv4/tcp_fastopen

# Socket Options
cat /proc/sys/net/core/somaxconn
cat /proc/sys/net/core/netdev_max_backlog

# MTU Settings
cat /proc/sys/net/ipv4/ip_no_pmtu_disc
cat /proc/sys/net/ipv4/tcp_mtu_probing
cat /proc/sys/net/ipv4/tcp_base_mss
```

### تست عملکرد BBR

```bash
# بررسی اتصالات فعال با BBR
ss -i | grep bbr

# یا
ss -i -t | grep bbr
```

## توضیحات تنظیمات

### BBR (Bottleneck Bandwidth and Round-trip propagation time)
- **هدف**: بهبود throughput و کاهش latency
- **مقدار**: `bbr` به عنوان congestion control

### TCP Buffers
- **rmem_max/wmem_max**: 128MB - حداکثر buffer برای receive/send
- **tcp_rmem**: `4096 87380 67108864` - min default max برای receive buffer
- **tcp_wmem**: `4096 65536 67108864` - min default max برای send buffer
- **tcp_mem**: `262144 524288 1048576` - min pressure max برای کل TCP memory

### TCP Window Scaling
- فعال‌سازی برای اتصالات با پهنای باند بالا و فاصله زیاد
- بهبود عملکرد در شبکه‌های با latency بالا

### TCP Fast Open
- کاهش latency در اتصالات جدید
- مقدار `3` یعنی فعال برای client و server

### Connection Tracking
- افزایش حداکثر تعداد اتصالات ردیابی شده
- مناسب برای سرورهای با تعداد کاربران بالا

### MTU Settings for Packet Tunnel
- **MTU پیش‌فرض**: 1350 بایت (بهینه برای اتصالات VPN/tunnel)
- **ip_no_pmtu_disc**: 0 - فعال‌سازی Path MTU Discovery
- **tcp_mtu_probing**: 1 - فعال‌سازی TCP MTU Probing برای بهینه‌سازی خودکار
- **tcp_base_mss**: 1024 - اندازه پایه MSS برای TCP
- **نکته**: برای TUN interfaces در Xray، MTU را در تنظیمات TUN تنظیم کنید: `"MTU": 1350`

## نکات مهم

1. **نیاز به root**: تمام دستورات نیاز به دسترسی root دارند
2. **پایداری**: فایل `/etc/sysctl.d/99-xray-optimization.conf` باعث اعمال خودکار بعد از reboot می‌شود
3. **ماژول BBR**: در برخی سیستم‌ها نیاز به بارگذاری دستی ماژول `tcp_bbr` است
4. **بررسی Kernel**: BBR نیاز به kernel 4.9+ دارد

## بازگشت به تنظیمات پیش‌فرض

```bash
# حذف فایل تنظیمات
sudo rm /etc/sysctl.d/99-xray-optimization.conf

# بازگشت به congestion control پیش‌فرض
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic

# اعمال تغییرات
sudo sysctl --system
```
