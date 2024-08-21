#!/bin/bash
set -e

# Update packages
sudo yum update -y

# Install required packages
sudo yum install -y wget tar unzip

# Install Prometheus
PROMETHEUS_VERSION="2.42.0"  # Replace with the latest version if needed
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus /var/log/prometheus
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus.yml /etc/prometheus/
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus
rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64*

# Create Prometheus systemd service file
sudo tee /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Create Prometheus user and group
sudo groupadd prometheus
sudo useradd -r -g prometheus -s /sbin/nologin prometheus

# Set ownership of Prometheus directories
sudo chown -R prometheus:prometheus /etc/prometheus /usr/local/bin/prometheus /var/lib/prometheus /var/log/prometheus

# Enable and start Prometheus service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Install Grafana
wget https://dl.grafana.com/oss/release/grafana-9.0.5-1.x86_64.rpm
sudo yum localinstall -y grafana-9.0.5-1.x86_64.rpm
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

LOKI_VERSION="2.8.0"
PROMTAIL_VERSION="2.8.0"
LOKI_URL="https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip"
PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"

# Create directories for Loki and Promtail
sudo mkdir -p /usr/local/bin/loki /usr/local/bin/promtail

# Download and install Loki
wget -O /tmp/loki.zip ${LOKI_URL}
sudo unzip /tmp/loki.zip -d /tmp/loki
sudo cp /tmp/loki/loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki

# Download and install Promtail
wget -O /tmp/promtail.zip ${PROMTAIL_URL}
sudo unzip /tmp/promtail.zip -d /tmp/promtail
sudo cp /tmp/promtail/promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail
