# 📡 AndroidLab

Build a controlled rogue Wi-Fi lab on Kali Linux, force an Android device to connect using ADB, and verify the connection at every OSI layer — from wireless association to live packet flow.

No root.
No third-party Android apps.
Just Linux, NetworkManager, ADB, and raw system inspection.

---

## 🔬 What This Project Demonstrates

* Create a Wi-Fi access point using `nmcli`
* Provision Android Wi-Fi via ADB
* Prove Layer 2 association
* Confirm DHCP IP assignment
* Inspect ARP tables
* Capture live traffic with `tcpdump`
* Analyze packets with Wireshark
* Validate Android Wi-Fi service state internally

This is not a “connect to hotspot” guide.

This is a reproducible wireless lab workflow for inspection and analysis.

---

# 🧰 Requirements

* Kali Linux (or compatible Linux distribution)
* Wireless interface capable of AP mode
* NetworkManager
* ADB installed
* Android device with USB debugging enabled

---

# 🚀 Automated Lab Wi-Fi + Android Provisioning

The `adb_wifi_provision.sh` script now:

* ✅ Creates the lab hotspot using NetworkManager
* ✅ Displays hotspot credentials
* ✅ Provisions the connected Android device via ADB

No manual `nmcli` commands required.

---

Clone the Repository

```bash
git clone https://github.com/DouglasFreshHabian/AndroidLab.git
cd AndroidLab
```

---

Make the Script Executable

```bash
chmod +x adb_wifi_provision.sh
```

---

Run the Automation Script

```bash
./adb_wifi_provision.sh
```

---

# 🚀 Step 1 — Creates the Lab Access Point

The script automatically runs:

```bash
nmcli device wifi hotspot ifname wlan0 ssid <SSID> password <PASSWORD>
```

NetworkManager automatically:

* Spawns `hostapd` internally
* Configures DHCP
* Manages WPA authentication

You will see output similar to:

```
SSID: Lab9
Security: WPA
Password: Password9
```

---

# 📱 Step 2 — Provisions Android via ADB

The script then:

* Prompts for SSID
* Prompts for password
* Pushes configuration using system-level Android Wi-Fi commands via ADB

Example prompt:

```
Enter SSID: Lab9
Password: Password9
```

Your Android device will automatically connect to the newly created lab access point.

---

# 🔎 Step 3 — Prove Layer 2 Association

Strongest proof:

```bash
iw dev wlan0 station dump
```

Example:

```
Station aa:bb:cc:dd:ee:ff (on wlan0)
    rx bytes:  15240
    tx bytes:  9321
    signal:    -38 dBm
```

This confirms:

* Association
* Authentication
* Signal strength
* Active data exchange

Live monitoring:

```bash
watch -n 1 "iw dev wlan0 station dump"
```

Toggle Wi-Fi on Android to see real-time changes.

---

# 🌐 Step 4 — Prove Layer 3 (IP Assignment)

NetworkManager typically assigns from:

```
10.42.0.0/24
```

Verify:

```bash
ip neigh show dev wlan0
```

Example:

```
10.42.0.34 lladdr aa:bb:cc:dd:ee:ff REACHABLE
```

Now you have:

* IP address
* MAC address
* Interface confirmation

---

# 📡 Step 5 — Observe Live Traffic

Start packet capture:

```bash
sudo tcpdump -i wlan0
```

Or filter DNS traffic:

```bash
sudo tcpdump -i wlan0 port 53
```

On Android:

```bash
adb shell ping 8.8.8.8
```

You will see DNS resolution and ICMP traffic in real time.

This confirms:

* Active transmission
* Routing functionality
* End-to-end connectivity

---

# 🦈 Step 6 — Visual Packet Analysis (Wireshark)

Launch:

```bash
sudo wireshark
```

Select:

* `any`
* or `wlan0`

Useful filters:

```
dns
icmp
arp
```

Generate traffic on Android to inspect:

* DNS queries
* ARP resolution
* ICMP echo requests

---

# 🤖 Step 7 — Confirm Android Internal State

From Linux:

```bash
adb shell cmd wifi status
adb shell ip address show wlan0
```

Optional deeper inspection:

```bash
adb shell dumpsys wifi
```

This allows you to correlate:

* BSSID
* RSSI
* Link speed
* Network ID

Now you have:

* Linux perspective
* Android perspective
* Packet-level visibility

---

# 🧱 Architecture Overview

```
[ Android Device ]
        |
     802.11
        |
[ Kali Hotspot (wlan0) ]
        |
     NAT / Routing
        |
     Internet
```

Validation layers:

* Layer 2 → Association (`iw`)
* Layer 3 → DHCP / ARP (`ip neigh`)
* Layer 4 → ICMP / DNS (`tcpdump`)
* Application → Browser traffic
* Android Internal → `cmd wifi`, `dumpsys wifi`

---

# 🛑 Teardown

Bring hotspot down:

```bash
nmcli connection down Hotspot
```
Delete hotspot:

```bash
nmcli connection delete Hotspot
```
---

# ⚠️ Disclaimer

This project is intended for:

* Personal lab environments
* Controlled testing
* Educational research

Do not deploy rogue access points on networks you do not own or explicitly control.

---

<!-- 
    Fresh Forensics, LLC | Douglas Fresh Habian | 2025
    github.com/DouglasFreshHabian
    freshforensicsllc@tuta.com
-->


<p align="left">
  <img src="https://github.com/DouglasFreshHabian/AndroidLab/blob/main/.github/Assets/qr.png" width="280"><br><br>
  <span style="font-size: 16px;">Scan to instantly watch the Video</span>
</p>
