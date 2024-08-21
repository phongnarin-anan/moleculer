#!/bin/bash
set -e
export ROUTE53_HOSTED_ZONE_ID="${ROUTE53_HOSTED_ZONE_ID}"
export SECRET_ID="${SECRET_ID}"
export SNS_TOPIC_ARN="${SNS_TOPIC_ARN}"
export INSTANCE_TYPE="${INSTANCE_TYPE}"
export REGION="${REGION}"
export ACCOUNT_ID="${ACCOUNT_ID}"

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
bash "01_set_hostname.sh"

# Create a Prometheus Service Discovery on EC2 Instance on Prometheus configuration
sudo tee /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.

scrape_configs:
  - job_name: 'node'
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: '/metrics'
    scheme: http
    ec2_sd_configs:
      - region: $REGION
        port: 9100
        role_arn: arn:aws:iam::$ACCOUNT_ID:role/EC2InstanceRole
    relabel_configs:
      #Use the instance ID as the instance label
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance
EOF

# Create Loki configuration file
sudo tee /etc/loki/local-config.yaml <<EOF
server:
  http_listen_port: 3100
  grpc_listen_port: 9095

ingester:
  chunk_target_size: 1048576
  max_chunk_age: 1h

common:
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

storage_config:
  tsdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    cache_ttl: 24h
  aws:
    s3: s3://$REGION
    bucketnames: install-artifact

schema_config:
  configs:
    - from: 2020-07-01
      store: tsdb
      object_store: aws
      schema: v11
      index:
        prefix: index_
        period: 24h

compactor:
  working_directory: /var/lib/loki/compactor
EOF

# Create Promtail configuration file
sudo mkdir -p /etc/promtail
sudo tee /etc/promtail/local-config.yaml <<EOF
server:
  http_listen_port: 3200
  grpc_listen_port: 9096

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: obs-server-varlogs
          __path__: /var/log/*log
EOF

# Start Loki and Promtail
sudo nohup /usr/local/bin/loki/loki-linux-amd64 -config.file=/etc/loki/local-config.yaml > /var/log/loki.log 2>&1 &
sudo nohup /usr/local/bin/promtail/promtail-linux-amd64 -config.file=/etc/promtail/local-config.yaml > /var/log/promtail.log 2>&1 &

# Start prometheus
sudo systemctl start prometheus

# Configure Grafana to serve from /grafana
sudo sed -i '/\[server\]/,/^$/s|^root_url = .*|root_url = http://your-new-url|g' config.ini
sudo sed -i 's|;serve_from_sub_path = false|serve_from_sub_path = true|' /etc/grafana/grafana.ini

# Start Grafana
sudo systemctl start grafana-server