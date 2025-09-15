#!/bin/bash

# VPN Sidecar Entrypoint
# Sets up VPN connection and maintains it, failing if VPN doesn't work

set -e

echo "🚀 Starting VPN Sidecar..."

# Validate required environment variables
if [ -z "$VPN_USERNAME" ] || [ -z "$VPN_PASSWORD" ]; then
    echo "❌ ERROR: VPN_USERNAME and VPN_PASSWORD environment variables are required"
    exit 1
fi

# Create auth file from credentials
echo "🔐 Setting up VPN credentials..."
echo "$VPN_USERNAME" > /tmp/auth.txt
echo "$VPN_PASSWORD" >> /tmp/auth.txt
chmod 600 /tmp/auth.txt

# Get current network info before starting VPN
DEFAULT_GW=$(ip route | grep default | awk '{print $3}')
DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}')
echo "🌐 Current gateway: $DEFAULT_GW via interface: $DEFAULT_IFACE"

# Pre-configure bypass routes for internal networks
echo "🔧 Pre-configuring bypass routes for internal networks..."

# Detect environment and configure appropriate bypass routes
if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
    # Running in Kubernetes - bypass cluster networks
    echo "🎯 Kubernetes environment detected"
    ip route add 10.42.0.0/16 via $DEFAULT_GW dev $DEFAULT_IFACE || true  # Pod network
    ip route add 10.0.0.0/8 via $DEFAULT_GW dev $DEFAULT_IFACE || true    # Service network
    ip route add 172.16.0.0/12 via $DEFAULT_GW dev $DEFAULT_IFACE || true # Private networks
    ip route add 192.168.0.0/16 via $DEFAULT_GW dev $DEFAULT_IFACE || true # Private networks
    echo "✅ Kubernetes cluster bypass routes configured"
else
    # Running in Docker Compose - bypass Docker networks
    echo "🐳 Docker Compose environment detected"
    # Get all current Docker networks and add bypass routes
    for network in $(ip route | grep -E "172\.(1[6-9]|2[0-9]|3[01])\." | awk '{print $1}' | sort -u); do
        ip route add $network via $DEFAULT_GW dev $DEFAULT_IFACE || true
    done
    # Add common Docker network ranges
    ip route add 172.17.0.0/16 via $DEFAULT_GW dev $DEFAULT_IFACE || true # Default bridge
    ip route add 172.18.0.0/16 via $DEFAULT_GW dev $DEFAULT_IFACE || true # Custom networks
    ip route add 172.19.0.0/16 via $DEFAULT_GW dev $DEFAULT_IFACE || true # Custom networks
    ip route add 172.20.0.0/16 via $DEFAULT_GW dev $DEFAULT_IFACE || true # Custom networks
    echo "✅ Docker Compose bypass routes configured"
fi

# OpenVPN will automatically add bypass route for the VPN server
echo "📝 Note: OpenVPN will automatically bypass VPN server traffic"

# Start OpenVPN in background with redirect-gateway to force all traffic through VPN
echo "🔗 Starting OpenVPN connection..."
openvpn --config /etc/openvpn/config.ovpn --auth-user-pass /tmp/auth.txt --redirect-gateway def1 --daemon

# Wait for OpenVPN to establish connection
echo "⏳ Waiting for OpenVPN to connect..."
for i in {1..60}; do
    if ip addr show tun0 >/dev/null 2>&1; then
        echo "✅ OpenVPN connected successfully"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ ERROR: OpenVPN failed to connect after 60 attempts"
        exit 1
    fi
    sleep 2
done

echo "✅ VPN connection established with bypass routes for internal connectivity"

# Validate VPN connection is working
echo "🔍 Validating VPN connection..."
if ! /usr/local/bin/validate-vpn.sh; then
    echo "❌ ERROR: VPN validation failed - sidecar will exit"
    exit 1
fi

echo "✅ VPN setup completed successfully"

# Keep the VPN connection alive and monitor it
echo "👁️  Starting VPN monitoring loop..."
while true; do
    if ip addr show tun0 >/dev/null 2>&1; then
        # Periodically validate VPN is still working (every 5 minutes)
        if [ $(($(date +%s) % 300)) -eq 0 ]; then
            echo "🔍 Periodic VPN validation..."
            if ! /usr/local/bin/validate-vpn.sh; then
                echo "❌ ERROR: VPN validation failed during monitoring - sidecar will exit"
                exit 1
            fi
            echo "✅ VPN connection healthy"
        fi
    else
        echo "⚠️  VPN connection lost, attempting to reconnect..."
        
        # Restart OpenVPN with same settings as initial connection
        openvpn --config /etc/openvpn/config.ovpn --auth-user-pass /tmp/auth.txt --redirect-gateway def1 --daemon
        
        # Wait for reconnection
        sleep 10
        if ip addr show tun0 >/dev/null 2>&1; then
            echo "✅ VPN reconnected successfully"
            # Validate reconnection worked
            if ! /usr/local/bin/validate-vpn.sh; then
                echo "❌ ERROR: VPN reconnection failed validation - sidecar will exit"
                exit 1
            fi
        else
            echo "❌ ERROR: VPN reconnection failed - sidecar will exit"
            exit 1
        fi
    fi
    sleep 30
done
