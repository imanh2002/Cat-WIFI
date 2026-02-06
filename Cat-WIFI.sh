#!/usr/bin/env bash

clear

cat << "EOF"
   /\\_/\\  
  ( o.o ) 
   > ^ <  

       Cat WIFI
   WiFi Hotspot Manager 🐱📡

   https://github.com/imanh2002

EOF

sleep 2

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="$HOME/catwifi.log"

UPDATE_INTERVAL=3

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_req() {
    for cmd in nmcli iw arp modprobe; do
        command -v "$cmd" &>/dev/null || {
            echo -e "${RED}Error: $cmd is not installed! 🚫${NC}"
            exit 1
        }
    done
    echo -e "${GREEN}All tools are ready ✅${NC}"
}

detect_ap_ifaces() {
    local wifi_ifaces=$(nmcli device | grep wifi | awk '{print $1}')
    local ap_ifaces=""
    for iface in $wifi_ifaces; do
        local phy=$(iw dev "$iface" info 2>/dev/null | grep wiphy | awk '{print "phy" $2}')
        if [ -n "$phy" ] && iw phy "$phy" info 2>/dev/null | grep -q "* AP"; then
            ap_ifaces="$ap_ifaces $iface"
        fi
    done
    echo "$ap_ifaces"
}

activate() {
    local ap_ifaces=$(detect_ap_ifaces)
    [ -z "$ap_ifaces" ] && { echo -e "${RED}No WiFi card supports AP mode! 🔴${NC}"; return 1; }

    echo -e "${BLUE}Available WiFi interfaces:${NC}"
    local i=1
    for iface in $ap_ifaces; do
        echo "$i) $iface"
        ((i++))
    done

    read -p "Choose number → " num
    local iface=$(echo "$ap_ifaces" | awk "{print \$$num}")
    [ -z "$iface" ] && { echo -e "${RED}Invalid choice! ❌${NC}"; return 1; }

    read -p "SSID (network name): " ssid
    read -s -p "Password (min 8 chars): " pass
    echo

    [ ${#pass} -lt 8 ] && { echo -e "${RED}Password too short! Minimum 8 characters 🔐${NC}"; return 1; }

    echo -e "${YELLOW}Starting hotspot... ⚡${NC}"

    sudo nmcli device set "$iface" managed yes 2>/dev/null || return 1

    if lsmod | grep -q rt2800usb; then
        sudo modprobe -r rt2800usb && sudo modprobe rt2800usb 2>/dev/null
    fi

    sudo nmcli device wifi hotspot ifname "$iface" ssid "$ssid" password "$pass" 2>/dev/null

    [ $? -eq 0 ] && echo -e "${GREEN}Hotspot is ON → $ssid 🔥${NC}" || echo -e "${RED}Failed to start hotspot! 😿${NC}"
}

deactivate() {
    local iface=$(detect_active_ap)
    [ -z "$iface" ] && { echo -e "${RED}No active hotspot found! 🔴${NC}"; return 1; }

    local ssid=$(sudo iw dev "$iface" info 2>/dev/null | grep ssid | awk '{print $2}')

    echo -e "${YELLOW}Turning off hotspot... ✂️${NC}"

    if [ -n "$ssid" ]; then
        sudo nmcli connection down "$ssid" 2>/dev/null
    fi

    sudo nmcli device disconnect "$iface" 2>/dev/null

    sudo nmcli device set "$iface" managed yes 2>/dev/null

    sudo nmcli device wifi rescan ifname "$iface" 2>/dev/null

    sleep 1.5

    local status=$(nmcli -t -f GENERAL.STATE device show "$iface" 2>/dev/null)
    if [[ "$status" == "disconnected" || "$status" == "unavailable" ]]; then
        echo -e "${GREEN}Hotspot turned OFF 🛑 → Wi-Fi back to normal mode${NC}"
    else
        echo -e "${GREEN}Hotspot stopped → current state: ${status}${NC}"
    fi
}

detect_active_ap() {
    local wifi_ifaces=$(nmcli device | grep wifi | awk '{print $1}')
    for iface in $wifi_ifaces; do
        sudo iw dev "$iface" info 2>/dev/null | grep -q "type AP" && echo "$iface" && return 0
    done
    return 1
}

monitor() {
    local iface=$(detect_active_ap)
    [ -z "$iface" ] && { echo -e "${RED}No active hotspot! Start one first 🔴${NC}"; return 1; }

    local ssid=$(sudo iw dev "$iface" info | grep ssid | awk '{print $2}')

    local prev_rx="/tmp/catwifi_rx_$iface"
    local prev_tx="/tmp/catwifi_tx_$iface"
    local prev_time="/tmp/catwifi_time_$iface"
    local prev_dev="/tmp/catwifi_dev_$iface"

    touch "$prev_dev"

    local running=1
    trap 'running=0' INT

    while [ $running -eq 1 ]; do
        clear

        cat << EOF
   /\\_/\\     Cat WIFI Monitor
  ( o.o )    SSID → $ssid
   > ^ <     Interface → $iface

   https://github.com/imanh2002

🕒 $(date '+%Y-%m-%d %H:%M:%S')
🔄 Refresh every $UPDATE_INTERVAL sec  (Ctrl+C → back)

---------------------------------------------
EOF

        local count=$(sudo iw dev "$iface" station dump | grep -c "Station")
        echo -e "${GREEN}Connected devices: $count 📱${NC}"

        local macs=$(sudo iw dev "$iface" station dump | grep "Station" | awk '{print $2}')

        local prev=$(cat "$prev_dev" 2>/dev/null)
        for mac in $macs; do
            echo "$prev" | grep -q "$mac" || echo -e "${YELLOW}→ New friend: $mac 🚪${NC}"
        done
        for mac in $prev; do
            echo "$macs" | grep -q "$mac" || echo -e "${YELLOW}← Goodbye: $mac 👋${NC}"
        done
        echo "$macs" > "$prev_dev"

        if [ $count -gt 0 ]; then
            for mac in $macs; do
                echo -e "${BLUE}┌─ $mac${NC}"

                local ip=$(arp -i "$iface" -a | grep "$mac" | awk '{gsub(/[()]/,"",$2); print $2}')
                [ -n "$ip" ] && echo "│  IP → $ip 🌐" || echo "│  IP → not found ⚠️"

                local sig=$(sudo iw dev "$iface" station dump | grep -A10 "Station $mac" | grep "signal:" | awk '{print $2 " dBm"}')
                echo "│  Signal → $sig 📶"

                local rx=$(sudo iw dev "$iface" station dump | grep -A10 "Station $mac" | grep "rx bytes" | awk '{print $3 " bytes"}')
                local tx=$(sudo iw dev "$iface" station dump | grep -A10 "Station $mac" | grep "tx bytes" | awk '{print $3 " bytes"}')
                echo "│  RX/TX → $rx / $tx 📊"

                local now=$(date +%s)
                local prx=$(cat "$prev_rx.$mac" 2>/dev/null || echo 0)
                local ptx=$(cat "$prev_tx.$mac" 2>/dev/null || echo 0)
                local ptime=$(cat "$prev_time.$mac" 2>/dev/null || echo $now)

                local dt=$((now - ptime)); [ $dt -eq 0 ] && dt=1
                local rs=$((( $(echo $rx | cut -d' ' -f1) - prx ) / dt ))
                local ts=$((( $(echo $tx | cut -d' ' -f1) - ptx ) / dt ))

                echo "$rx" | cut -d' ' -f1 > "$prev_rx.$mac"
                echo "$tx" | cut -d' ' -f1 > "$prev_tx.$mac"
                echo "$now" > "$prev_time.$mac"

                echo "│  Speed → ↓ ${rs} B/s   ↑ ${ts} B/s ⚡"

                local inact=$(sudo iw dev "$iface" station dump | grep -A10 "Station $mac" | grep "inactive time" | awk '{print $3 " ms"}')
                echo "│  Inactive → $inact ⏳"
                echo "└──────────────────────────────────────"
            done
        else
            echo -e "${RED}No one is here right now 😿${NC}"
        fi

        echo -e "${YELLOW}Logs → $LOG_FILE 📝${NC}"
        sleep $UPDATE_INTERVAL
    done

    rm -f /tmp/catwifi_* 2>/dev/null
    echo -e "${GREEN}Monitoring stopped. Back to menu... 🐱${NC}"
    trap - INT
}

main() {
    check_req

    while true; do
        clear

        cat << "EOF"
   /\\_/\\  
  ( o.o ) 
   > ^ <  

       Cat WIFI
   WiFi Hotspot Manager 🐱📡

   https://github.com/imanh2002

1) Turn ON Hotspot    🔥
2) Turn OFF Hotspot   🛑
3) Monitor Devices    👁

EOF

        read -p "Choose (1-3) → " opt

        case $opt in
            1) activate ;;
            2) deactivate ;;
            3) monitor ;;
            *) echo -e "${RED}Wrong choice! Try again 😿${NC}" ;;
        esac

        read -p "Press Enter to continue..."
    done
}

trap 'echo -e "\n${GREEN}See you later! 🐾${NC}"; rm -f /tmp/catwifi_* 2>/dev/null; exit 0' INT
trap 'rm -f /tmp/catwifi_* 2>/dev/null' EXIT
main
