import json
import boto3
import os

def lambda_handler(event, context):
    route53 = boto3.client('route53')
    
    # Retrieve hosted zone ID from environment variable
    hosted_zone_id = os.environ['HOSTED_ZONE_ID']
    
    if not hosted_zone_id:
        return {
            'statusCode': 500,
            'body': json.dumps('Environment variable HOSTED_ZONE_ID is not set.')
        }

    # Extract the IP address and record name from the SNS message
    for record in event['Records']:
        sns_message = json.loads(record['Sns']['Message'])
        private_ip = sns_message.get('private_ip')
        record_name = sns_message.get('record_name')

        if not private_ip or not record_name:
            return {
                'statusCode': 400,
                'body': json.dumps('No IP address or record name found in the SNS message.')
            }

        # Create the JSON payload for the DNS update
        change_batch = {
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": record_name,
                        "Type": "A",
                        "TTL": 60,
                        "ResourceRecords": [
                            {
                                "Value": private_ip
                            }
                        ]
                    }
                }
            ]
        }

        # Update the DNS record in Route 53
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch=change_batch
        )

        # Print response
        print(json.dumps(response, indent=2))

    return {
        'statusCode': 200,
        'body': json.dumps(f'DNS record {record_name} updated with IP {private_ip}')
    }
