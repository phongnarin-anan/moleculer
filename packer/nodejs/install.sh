#!/bin/bash
set -e

# Update packages
sudo yum update -y

# Install Node.js and npm (including latest Node.js LTS)
# Amazon Linux 2 uses `nodejs` from the EPEL repository
sudo yum install -y nodejs npm

# Define local paths
APP_DIR="/opt/js"

# Create application directory
mkdir -p $APP_DIR
cd $APP_DIR

# Install npm modules
npm install moleculer moleculer-web aws-sdk nats

# Create log path
mkdir /var/log/nodejs

# Install AWS CLI
sudo yum install -y aws-cli

# Install Prometheus Node Exporter
NODE_EXPORTER_VERSION="1.4.0"  # You can check for the latest version on the Prometheus website
NODE_EXPORTER_TAR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_TAR}"

# Download Node Exporter
curl -LO ${NODE_EXPORTER_URL}

# Extract the tarball
tar xvf ${NODE_EXPORTER_TAR}

# Move the binary to /usr/local/bin
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Clean up downloaded files
rm -rf ${NODE_EXPORTER_TAR} node_exporter-${NODE_EXPORTER_VERSION}

# Create a Node Exporter user
sudo useradd --no-create-home --shell /sbin/nologin node_exporter

# Create a systemd service file for Node Exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Start and enable the Node Exporter service
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verify Node Exporter is running
sudo systemctl status node_exporter

## Grafana Loki
# Define versions and URLs
PROMTAIL_VERSION="2.8.0"
PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"

# Create directories for Promtail
sudo mkdir -p /usr/local/bin/promtail

# Download and install Promtail
wget -O /tmp/promtail.zip ${PROMTAIL_URL}
sudo unzip /tmp/promtail.zip -d /tmp/promtail
sudo cp /tmp/promtail/promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail