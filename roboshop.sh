#!/bin/bash

ami_id="ami-09c813fb71547fc4f"
sg_id="sg-026125864f002d1cd"
zone_id="Z03322182ZV3F5YEDZYG5"
domain="surekhadevops.biz"

for instance in $@
do
    instance_id=$(aws ec2 run-instances --image-id $ami_id --instance-type t2.micro --security-group-ids $sg_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    if [ $instance != 'frontend' ]; then
        ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        record_name="$instance.$domain"
    else
        ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        record_name="$domain"
    fi

    echo "$instance: $ip"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch '
    {
        "Comment": "Updatind record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$record_name'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$ip'"
            }]
        }
        }]
    }
    '
done