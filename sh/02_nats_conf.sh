#!/bin/bash
set -e

# Retrieve NATS credentials from AWS Secrets Manager
SECRET_ID="${SECRET_ID}"
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --query 'SecretString' --output text)

# Extract NATS credentials
NATS_USER=$(echo "$SECRET_JSON" | jq -r '.username')
NATS_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

# Define a function to get the list of NATS server IPs from AWS Route 53 or another service
get_nats_cluster_nodes() {
  # Retrieve all records and filter for names matching "nats.*"
  aws route53 list-resource-record-sets --hosted-zone-id "$ROUTE53_HOSTED_ZONE_ID" --query "ResourceRecordSets[*]" --output json | jq -r '.[] | select(.Name | test("nats.*")) | .Name'
}

# Update the NATS server configuration file
sudo mkdir -p /etc/nats
update_nats_config() {
  local cluster_nodes="$1"

  cat <<EOF | sudo tee /etc/nats/nats-server.conf
# NATS server configuration

# Listen on a public port
port: 4222

# Authentication
authorization {
  users = [
    {user: "$NATS_USER", password: "$NATS_PASSWORD"}
  ]
}

# Logging
log_file: "/var/log/nats-server.log"

# Clustering configuration
cluster {
  # Cluster port
  port: 6222

  # Routes to connect to other cluster nodes
  routes = [
    $(echo "$cluster_nodes" | awk '{print "nats://"$1":6222"}' | paste -sd, -)
  ]
}

# HTTP monitoring port
http_port: 8222
EOF
}

# Create log directory and set permissions
sudo mkdir -p /var/log/nats-server
sudo chown $(whoami):$(whoami) /var/log/nats-server

# Get the current list of NATS cluster nodes
CLUSTER_NODES=$(get_nats_cluster_nodes)

# Update the NATS server configuration with the list of cluster nodes
update_nats_config "$CLUSTER_NODES"

# Start NATS Server
sudo nats-server -c /etc/nats/nats-server.conf &
