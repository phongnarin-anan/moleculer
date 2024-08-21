#!/bin/bash
set -e

# Update packages
sudo yum update -y

# Install necessary packages
sudo yum install -y unzip jq wget

# Install NATS Server
wget https://github.com/nats-io/nats-server/releases/download/v2.9.18/nats-server-v2.9.18-linux-amd64.zip
unzip nats-server-v2.9.18-linux-amd64.zip
cd nats-server-v2.9.18-linux-amd64
sudo mv nats-server /usr/local/bin/

# Install Prometheus NATS Exporter
NATS_EXPORTER_VERSION="0.15.0"
wget https://github.com/nats-io/prometheus-nats-exporter/releases/download/v${NATS_EXPORTER_VERSION}/prometheus-nats-exporter-v${NATS_EXPORTER_VERSION}-linux-x86_64.tar.gz
tar xvf prometheus-nats-exporter-v${NATS_EXPORTER_VERSION}-linux-x86_64.tar.gz
sudo mv prometheus-nats-exporter /usr/local/bin/
rm -rf prometheus-nats-exporter-${NATS_EXPORTER_VERSION}-linux-x86_64*

# Create Prometheus NATS Exporter systemd service file
sudo tee /etc/systemd/system/nats_exporter.service <<EOF
[Unit]
Description=NATS Exporter for Prometheus
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/prometheus-nats-exporter -p 9100 -varz http://localhost:8222
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd the NATS Exporter service
sudo systemctl daemon-reload
sudo systemctl enable nats_exporter

echo "NATS server and Prometheus exporter have been installed and started."

# Create directories for Promtail
sudo mkdir -p /usr/local/bin/promtail

## Grafana Loki
# Define versions and URLs
PROMTAIL_VERSION="2.8.0"
PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"

# Download and install Promtail
wget -O /tmp/promtail.zip ${PROMTAIL_URL}
sudo unzip /tmp/promtail.zip -d /tmp/promtail
sudo cp /tmp/promtail/promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail