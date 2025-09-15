#!/bin/bash

# VPN Validation Script
# Validates that VPN connection is working properly

set -e

MAX_RETRIES=30
RETRY_INTERVAL=2

echo "🔍 Validating VPN connection..."

# Wait for VPN interface to be available
echo "⏳ Waiting for tun0 interface..."
for i in $(seq 1 $MAX_RETRIES); do
    if ip addr show tun0 >/dev/null 2>&1; then
        echo "✅ tun0 interface is up"
        break
    fi
    if [ $i -eq $MAX_RETRIES ]; then
        echo "❌ ERROR: tun0 interface not available after ${MAX_RETRIES} attempts"
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

# Get the VPN IP from tun0 interface
VPN_INTERFACE_IP=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$VPN_INTERFACE_IP" ]; then
    echo "❌ ERROR: Could not get IP from tun0 interface"
    exit 1
fi
echo "🔍 VPN interface IP: $VPN_INTERFACE_IP"

# For now, just validate that tun0 interface exists and has an IP
# The actual external IP check will be done by your application
echo "🌐 Basic VPN validation - checking tun0 interface..."
if [ -n "$VPN_INTERFACE_IP" ]; then
    echo "✅ VPN validation successful - tun0 interface active with IP: $VPN_INTERFACE_IP"
    echo "📝 Note: External IP routing will be validated by your application"
    exit 0
else
    echo "❌ ERROR: tun0 interface has no IP address"
    exit 1
fi
