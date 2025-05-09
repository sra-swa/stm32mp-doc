#!/bin/sh

# Assign command-line arguments to variables
SSID_OF_NETWORK="ssid"
PASSWORD_OF_NETWORK="password"
HOSTNAME="rbt15"

cd ~

# Create the WiFi setup script
cat <<EOF > setup_wifi.sh
#!/bin/bash

# Set the hostname
hostnamectl set-hostname $HOSTNAME

# Create the networkd configuration file for wlan0
echo "[Match]" > /lib/systemd/network/51-wireless.network
echo "Name=wlan0" >> /lib/systemd/network/51-wireless.network
echo "[Network]" >> /lib/systemd/network/51-wireless.network
echo "DHCP=ipv4" >> /lib/systemd/network/51-wireless.network


# Bring up the wireless interface
ifconfig wlan0 up


# Create the wpa_supplicant configuration directory
mkdir -p /etc/wpa_supplicant/

# Create the wpa_supplicant configuration file
echo "ctrl_interface=/var/run/wpa_supplicant" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
echo "eapol_version=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
echo "ap_scan=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
echo "fast_reauth=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
echo "" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
wpa_passphrase $SSID_OF_NETWORK $PASSWORD_OF_NETWORK >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Enable the wpa_supplicant service for wlan0
systemctl enable wpa_supplicant@wlan0.service

# Restart the systemd-networkd and wpa_supplicant services
systemctl restart systemd-networkd.service
systemctl restart wpa_supplicant@wlan0.service

echo "WiFi setup completed."
EOF

chmod +x setup_wifi.sh
./setup_wifi.sh
rm setup_wifi.sh

# Copy the setup script to the STM32MP board
#scp setup_wifi.sh root@$IP_ADDRESS:/root/

# SSH into the STM32MP board and execute the script
#ssh root@$IP_ADDRESS <<'EOF'
#chmod +x /root/setup_wifi.sh
#sudo /root/setup_wifi.sh
#EOF

#echo "WiFi setup script executed on STM32MP board."