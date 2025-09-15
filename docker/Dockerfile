FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    openvpn \
    curl \
    wget \
    iproute2 \
    iptables \
    iputils-ping \
    dnsutils \
    net-tools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create necessary directories
RUN mkdir -p /etc/openvpn /tmp/vpn

# Add VPN validation script
COPY scripts/validate-vpn.sh /usr/local/bin/validate-vpn.sh
RUN chmod +x /usr/local/bin/validate-vpn.sh

# Add VPN sidecar entrypoint
COPY scripts/vpn-sidecar-entrypoint.sh /usr/local/bin/vpn-sidecar-entrypoint.sh
RUN chmod +x /usr/local/bin/vpn-sidecar-entrypoint.sh

# Set working directory
WORKDIR /tmp/vpn

# Use the VPN sidecar entrypoint
ENTRYPOINT ["/usr/local/bin/vpn-sidecar-entrypoint.sh"]
