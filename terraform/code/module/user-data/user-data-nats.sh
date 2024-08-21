#!/bin/bash
set -e
export ROUTE53_HOSTED_ZONE_ID="${ROUTE53_HOSTED_ZONE_ID}"
export SECRET_ID="${SECRET_ID}"
export SNS_TOPIC_ARN="${SNS_TOPIC_ARN}"
export INSTANCE_TYPE="${INSTANCE_TYPE}"

# Define S3 bucket and path
S3_BUCKET="install-artifact"
S3_PATH_SH="sh"

# Create sh directory
SH_DIR="/opt/sh"
mkdir -p $SH_DIR

# Download Shell files from S3 bucket
aws s3 cp s3://$S3_BUCKET/$S3_PATH_SH/ $SH_DIR/ --recursive

# Change to the shell directory
cd $SH_DIR

# Execute sh script to setup the server
for script in *.sh; do
    bash "$script"
done

# Create Promtail configuration file
sudo mkdir -p /etc/promtail
sudo tee /etc/promtail/local-config.yaml <<EOF
server:
  http_listen_port: 3100

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki.local:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: nats-serverlog
          __path__: /var/log/nats-server.log
EOF

# Start Promtail
sudo nohup /usr/local/bin/promtail/promtail-linux-amd64 -config.file=/etc/promtail/local-config.yaml > /var/log/promtail.log 2>&1 &

# Start the NATS Exporter service
sudo systemctl start nats_exporter