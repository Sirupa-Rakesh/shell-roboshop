#!/bin/bash


SG_ID="sg-08f36e4129a352630" #replace with your id
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z06093173S4YOZ3599SC6"
DOMAIN_NAME="daws-88s.online"


for instance in "$@"
do 
     INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

    if [  "$instance" == "frontend" ]; then 
        IP=$(
             aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[].Instances[].PublicIpAddress" \
            --output text
        )
        else
        RECORD_NAME="$DOMAIN_NAME" # daws88s.online
         IP=$(
             aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[].Instances[].PrivateIpAddress" \
            --output text 
        )
         RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.daws88s.online
    fi
    echo "IPADDRESS: $IP"
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '

    echo "record updated for $instance"
done
