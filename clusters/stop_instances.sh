#!/bin/bash -e
IFS=$'\n'

terraform workspace select default
cluster_instances=${1:-1}
aws_profile="${2:-rancher-eng}"
aws_region="${3:-us-west-1}"
workspace_prefix="${4:-workspace}"
workspaces=$(terraform workspace list | grep "workspace" | sed 's/*/ /' | sort -r)
counter=1
for workspace in ${workspaces}; do
  if [ "${counter}" -le $cluster_instances ]; then
    workspace="$(echo -e "${workspace}" | tr -d '[:space:]')"
    if [ "${workspace}" == "default" ]; then
      continue
    fi
    terraform workspace select "${workspace}"
    echo "getting workspace's aws_instance information: ${workspace}"
    instance_id=$(terraform output -raw instance_id)
    echo "stopping workspace's aws_instance: ${instance_id}"
    aws --profile="${aws_profile}" --region="${aws_region}" ec2 stop-instances --instance-ids "${instance_id}"
    counter=$((counter + 1))
  fi
done

terraform workspace select default
