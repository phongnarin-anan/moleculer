#!/bin/bash
set -e
export ROUTE53_HOSTED_ZONE_ID="${ROUTE53_HOSTED_ZONE_ID}"
export SECRET_ID="${SECRET_ID}"

# Start and enable the Node Exporter service
sudo systemctl start node_exporter

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
          job: apiservice-applog
          __path__: /var/log/nodejs/app.log
EOF

# Start Promtail
sudo nohup /usr/local/bin/promtail/promtail-linux-amd64 -config.file=/etc/promtail/local-config.yaml > /var/log/promtail.log 2>&1 &

# Define S3 bucket and paths
S3_BUCKET="install-artifact"
S3_PATH_JS="js" # Path for JavaScript files

# Define local paths
APP_DIR="/opt/js"

# # Create application directory
# mkdir -p $APP_DIR

# Download JavaScript files from S3 bucket
aws s3 cp s3://$S3_BUCKET/$S3_PATH_JS/ $APP_DIR/ --recursive

# Change to the application directory
cd $APP_DIR

# Start the API service
#npm install moleculer moleculer-web aws-sdk nats
mkdir /var/log/nodejs
ROUTE53_HOSTED_ZONE_ID="${ROUTE53_HOSTED_ZONE_ID}" SECRET_ID="${SECRET_ID}" node api-service.js > /var/log/nodejs/app.log 2>&1 &