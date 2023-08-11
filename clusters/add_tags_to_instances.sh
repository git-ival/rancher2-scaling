#!/usr/bin/env bash
### Get all instance ids in region, can add more specific filters as needed
instance_ids=$(aws --profile="rancher-eng" --region="us-west-1" ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text)

### Add tags to each instance
aws --profile="rancher-eng" --region="us-west-1" ec2 create-tags --resources ${instance_ids} --tags Key=DoNotDelete,Value=true
aws --profile="rancher-eng" --region="us-west-1" ec2 create-tags --resources ${instance_ids} --tags Key=Owner,Value=AIDAR2PTKWHFZSK6UIOLF
