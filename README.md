# Cat WIFI 🐱📡👁

A cute, terminal-based WiFi hotspot manager for Linux  
Build, stop, and monitor your personal WiFi hotspot with a smiling cat watching over everything 😸

https://github.com/imanh2002/Cat-WIFI

## ✨ What it does

- 🎯 **Turn ON** a WiFi hotspot (Access Point mode) in seconds  
- 🛑 **Turn OFF** hotspot and return your WiFi card to normal client/scanning mode  
- 👁 **Live monitoring** of connected devices with beautiful real-time stats

### Live monitoring shows you

- Number of connected devices  
- Each device's MAC address  
- Assigned IP address (via ARP)  
- Signal strength (dBm) 📶  
- Total downloaded / uploaded data (RX / TX bytes)  
- Real-time download & upload speed (Bytes per second) ⚡  
- Inactive time (how long since last activity) ⏳  
- Colorful notifications when someone connects or disconnects 🚪👋

Everything wrapped in colorful output + emoji + adorable cat art 🐾

## 📋 Requirements

### Required packages

```bash
# ────────────── Debian / Ubuntu / Linux Mint / Pop!_OS ──────────────
sudo apt update
sudo apt install -y network-manager iw wireless-tools net-tools

# ────────────── Fedora / CentOS Stream / RHEL ──────────────
sudo dnf install -y NetworkManager iw wireless-tools net-tools

# ────────────── Arch Linux / Manjaro ──────────────
sudo pacman -Syu networkmanager iw wireless_tools net-tools
```

## 🚀 Installation & Quick Start

```bash
wget https://raw.githubusercontent.com/imanh2002/Cat-WIFI/main/Cat-WIFI.sh
```

Or

```bash
git clone https://github.com/imanh2002/Cat-WIFI.git
cd Cat-WIFI
```

## 🐱 How to use

```bash
chmod +x Cat-WIFI.sh
sudo ./Cat-WIFI.sh
```

## After running, you will see this menu:

```bash
   /\\_/\\  
  ( o.o ) 
   > ^ <  

       Cat WIFI
   WiFi Hotspot Manager 🐱📡

   https://github.com/imanh2002

1) Turn ON Hotspot    🔥
2) Turn OFF Hotspot   🛑
3) Monitor Devices    👁
```
