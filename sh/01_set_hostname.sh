#!/bin/bash
set -e

# Retrieve the IMDSv2 token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Retrieve the current internal IP address using ifconfig
PRIVATE_IP=$(ifconfig enX0 | grep 'inet ' | awk '{print $2}')

# Set the instance name and start count
if [ "$INSTANCE_TYPE" == "nats" ]; then
  INSTANCE_NAME="nats"
else
  INSTANCE_NAME="loki"
fi
COUNT=1

# VPC ID for the current instance using IMDSv2
VPC_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/mac)/vpc-id)

# Check for existing instances in the VPC with the same tag name
EXISTING_INSTANCE_TAG_NAME=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value" --output text)

# Increment the count until a unique tag name is found
while echo "$EXISTING_INSTANCE_TAG_NAME" | grep -q "${INSTANCE_NAME}-$COUNT"; do
  COUNT=$((COUNT + 1))
done

# Final unique instance tag name
INSTANCE_TAG_NAME="${INSTANCE_NAME}-$COUNT"

# Retrieve the EC2 instance ID using IMDSv2
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# Tag the current EC2 instance
aws ec2 create-tags \
  --resources "$INSTANCE_ID" \
  --tags Key=Name,Value="$INSTANCE_TAG_NAME"

# Initial record name after checking for duplicates
RECORD_NAME="${INSTANCE_TAG_NAME}.local"

# SNS Topic ARN from environment variable
SNS_TOPIC_ARN="${SNS_TOPIC_ARN}"

# Check if SNS_TOPIC_ARN is set
if [ -z "$SNS_TOPIC_ARN" ]; then
  echo "Error: SNS_TOPIC_ARN environment variable is not set." >> /tmp/start.ltxt
  exit 1
fi

# Publish both the record name and the internal IP address to SNS
aws sns publish \
  --topic-arn "$SNS_TOPIC_ARN" \
  --message "{\"record_name\":\"$RECORD_NAME\", \"private_ip\":\"$PRIVATE_IP\"}"

echo "Published record name $RECORD_NAME and internal IP $PRIVATE_IP to SNS topic $SNS_TOPIC_ARN" >> /tmp/start.ltxt
