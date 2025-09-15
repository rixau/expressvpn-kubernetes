#!/bin/bash

# ExpressVPN Kubernetes Test Script
# Quick test to verify VPN functionality

set -e

echo "🧪 ExpressVPN Kubernetes Sidecar Test"
echo "======================================"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found"
    echo "📝 Please copy env.example to .env and add your ExpressVPN credentials"
    echo "   cp env.example .env"
    exit 1
fi

# Check if ExpressVPN config exists
if [ ! -f ovpn/config.ovpn ]; then
    echo "❌ ERROR: ExpressVPN config not found"
    echo "📝 Please download your .ovpn file from ExpressVPN and save it as:"
    echo "   ovpn/config.ovpn"
    echo "📖 See ovpn/README.md for detailed instructions"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Get current real IP for comparison
echo "🔍 Getting your real IP address..."
REAL_IP=$(curl -s --max-time 10 http://httpbin.org/ip | grep -o '"origin": "[^"]*"' | cut -d'"' -f4 || echo "unknown")
echo "📍 Your real IP: $REAL_IP"
echo ""

# Start the test
echo "🚀 Starting ExpressVPN sidecar test..."
echo "⏳ This will take about 30-60 seconds..."
echo ""

# Start in detached mode
docker compose up -d expressvpn-sidecar

# Wait for VPN to connect
echo "⏳ Waiting for VPN connection..."
sleep 30

# Check VPN status
echo "🔍 Checking VPN connection..."
VPN_IP=$(docker exec expressvpn-sidecar curl -s --max-time 10 http://httpbin.org/ip | grep -o '"origin": "[^"]*"' | cut -d'"' -f4 || echo "error")

echo ""
echo "📊 Results:"
echo "🏠 Real IP:    $REAL_IP"
echo "🔒 VPN IP:     $VPN_IP"
echo ""

if [ "$VPN_IP" != "$REAL_IP" ] && [ "$VPN_IP" != "error" ] && [ -n "$VPN_IP" ]; then
    echo "🎉 SUCCESS: VPN is working!"
    echo "✅ Traffic is routing through ExpressVPN"
    echo ""
    echo "🌐 Test the web interface:"
    echo "   docker compose up -d test-web"
    echo "   Open: http://localhost:8080"
else
    echo "❌ FAILURE: VPN is not working properly"
    echo "🔍 Check the logs: docker logs expressvpn-sidecar"
fi

echo ""
echo "🧹 To clean up: docker compose down"
