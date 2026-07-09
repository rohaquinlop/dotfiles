#!/bin/bash
# Fix thermald on ThinkPad X1 Carbon Gen 9
# Run with: bash ~/.config/hypr/scripts/fix-thermald.sh

set -e

echo "🔧 Creating thermald override for ThinkPad..."
sudo mkdir -p /etc/systemd/system/thermald.service.d
sudo tee /etc/systemd/system/thermald.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/thermald --systemd --dbus-enable --adaptive --ignore-cpuid-check
EOF

echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "🚀 Starting thermald..."
sudo systemctl start thermald

echo "✅ Verifying thermald status..."
systemctl status thermald --no-pager | head -5

echo ""
echo "Switching power profile to balanced..."
powerprofilesctl set balanced
echo "✅ Power profile: $(powerprofilesctl get)"
