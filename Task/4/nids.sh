#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit
fi

echo "Installing Suricata..."
sudo apt-get update
sudo apt-get install suricata -y

INTERFACE=$(ip link show | awk '/state UP/ {print $2}' | tr -d ':')
if [ -z "$INTERFACE" ]; then
  echo "No active network interface found!"
  exit 1
fi
echo "Detected active interface: $INTERFACE"

RULES_FILE="/etc/suricata/rules/local.rules"
echo "Configuring Suricata rules..."

cat > $RULES_FILE << EOL
# Rule 1: Detect ICMP ping
alert icmp any any -> any any (msg:"ICMP Ping Detected"; sid:1000001; rev:1;)

# Rule 2: Detect SSH connections
alert tcp any any -> any 22 (msg:"SSH Connection Detected"; sid:1000002; rev:1;)

# Rule 3: Detect HTTP traffic
alert tcp any any -> any 80 (msg:"HTTP Traffic Detected"; sid:1000003; rev:1;)
EOL

echo "Running Suricata on interface $INTERFACE..."
sudo suricata -c /etc/suricata/suricata.yaml -i $INTERFACE
