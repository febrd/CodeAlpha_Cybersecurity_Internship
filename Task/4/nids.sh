#!/bin/bash
echo "Updating system packages..."
sudo apt-get update
echo "Installing Snort..."
sudo apt-get install -y snort

if ! command -v snort &> /dev/null; then
  echo "Snort could not be installed. Exiting..."
  exit 1
fi

echo "Configuring Snort..."
RULES_FILE="/etc/snort/rules/local.rules"

echo 'alert icmp any any -> any any (msg:"ICMP Ping Detected"; sid:1000001; rev:1;)' > $RULES_FILE
SNORT_CONF="/etc/snort/snort.conf"

if grep -q "include \$RULE_PATH/local.rules" $SNORT_CONF; then
  echo "Local rules are already included in Snort configuration."
else
  echo "include \$RULE_PATH/local.rules" >> $SNORT_CONF
fi

echo "Restarting Snort service..."
systemctl restart snort

INTERFACE="eth0"
echo "Running Snort on interface $INTERFACE..."
snort -A console -q -i $INTERFACE -c /etc/snort/snort.conf

echo "Snort is now running and monitoring traffic on $INTERFACE."
