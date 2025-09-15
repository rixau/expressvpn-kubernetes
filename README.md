# ExpressVPN Kubernetes Sidecar

A production-ready ExpressVPN sidecar container for Kubernetes that provides VPN connectivity to your pods with automatic failover and validation.

## 🎯 Features

- **🔒 Secure VPN Integration**: Seamlessly add ExpressVPN to any Kubernetes pod or Docker container
- **🚀 Fail-Fast Behavior**: Container fails if VPN connection cannot be established
- **🔄 Auto-Reconnection**: Automatically reconnects if VPN connection drops
- **🌐 Environment Detection**: Works in both Kubernetes and Docker Compose environments
- **📊 Health Monitoring**: Continuous VPN connection monitoring and validation
- **🛡️ Network Isolation**: Proper routing for internal vs external traffic

## 🧪 Quick Test

Test the ExpressVPN sidecar locally with Docker Compose:

```bash
# 1. Clone the repository
git clone https://github.com/rixau/expressvpn-kubernetes.git
cd expressvpn-kubernetes

# 2. Set up credentials
cp env.example .env
# Edit .env with your ExpressVPN credentials

# 3. Add your ExpressVPN config
# Download your .ovpn file and save it as ovpn/config.ovpn

# 4. Test the VPN
docker compose up

# 5. Check the results
# - Watch the logs for VPN connection status
# - Visit http://localhost to see the IP test page
# - Check docker logs ip-test-app for detailed IP verification
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster
- ExpressVPN subscription and credentials
- ExpressVPN `.ovpn` configuration file

### 1. Create ExpressVPN Configuration

Download your ExpressVPN configuration from [ExpressVPN Setup](https://www.expressvpn.com/setup#manual) and create a ConfigMap:

```bash
kubectl create configmap expressvpn-config \
  --from-file=config.ovpn=your-expressvpn-config.ovpn \
  --namespace=your-namespace
```

### 2. Create Credentials Secret

```bash
kubectl create secret generic expressvpn-credentials \
  --from-literal=username='your_expressvpn_username' \
  --from-literal=password='your_expressvpn_password' \
  --namespace=your-namespace
```

### 3. Deploy Your Application with ExpressVPN Sidecar

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-expressvpn
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-expressvpn
  template:
    metadata:
      labels:
        app: app-with-expressvpn
    spec:
      shareProcessNamespace: true
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: app
        image: your-app:latest
        # Your application configuration
      - name: expressvpn-sidecar
        image: ghcr.io/rixau/expressvpn-kubernetes:latest
        env:
        - name: VPN_USERNAME
          valueFrom:
            secretKeyRef:
              name: expressvpn-credentials
              key: username
        - name: VPN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: expressvpn-credentials
              key: password
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
          privileged: true
        volumeMounts:
        - name: tun-device
          mountPath: /dev/net/tun
        - name: expressvpn-config
          mountPath: /etc/openvpn
      volumes:
      - name: expressvpn-config
        configMap:
          name: expressvpn-config
      - name: tun-device
        hostPath:
          path: /dev/net/tun
```

## 📖 Documentation

### How It Works

1. **VPN Sidecar**: Establishes ExpressVPN connection with proper routing
2. **Network Sharing**: Your application shares the VPN network namespace
3. **Automatic Routing**: External traffic goes through VPN, internal traffic bypasses VPN
4. **Health Monitoring**: Continuous monitoring ensures VPN stays connected
5. **Fail-Fast**: Pod exits if VPN connection fails, preventing unprotected traffic

### Environment Detection

The sidecar automatically detects the environment and configures appropriate bypass routes:

- **Kubernetes**: Bypasses cluster networks (10.42.0.0/16, 10.0.0.0/8, etc.)
- **Docker Compose**: Bypasses Docker networks (172.x.x.x ranges)

### Network Configuration

- **hostNetwork: true**: Ensures VPN affects the entire pod
- **shareProcessNamespace: true**: Allows network namespace sharing
- **dnsPolicy: ClusterFirstWithHostNet**: Proper DNS resolution

## 🔧 Configuration

### Environment Variables

- `VPN_USERNAME`: Your ExpressVPN username
- `VPN_PASSWORD`: Your ExpressVPN password

### Volume Mounts

- `/dev/net/tun`: Required for VPN tunnel creation
- `/etc/openvpn/config.ovpn`: Your ExpressVPN configuration file

## 📁 Examples

- [`examples/kubernetes/`](examples/kubernetes/): Complete Kubernetes deployment examples
- [`examples/docker-compose/`](examples/docker-compose/): Docker Compose setup for local testing

## 🏗️ Building

The Docker image is automatically built and published to `ghcr.io/rixau/expressvpn-kubernetes:latest` via GitHub Actions.

To build locally:
```bash
docker build -f docker/Dockerfile -t expressvpn-kubernetes .
```

## 🔒 Security Considerations

- **Privileged Containers**: Required for VPN functionality
- **NET_ADMIN Capability**: Needed for network configuration
- **Credential Management**: Use Kubernetes secrets, never hardcode credentials
- **Network Isolation**: Proper routing ensures internal traffic stays internal

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This project is not affiliated with ExpressVPN. ExpressVPN is a trademark of Express VPN International Ltd.
