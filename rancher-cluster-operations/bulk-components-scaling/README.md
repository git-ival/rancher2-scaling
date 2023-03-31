# bulk-components-scaling

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_rancher2"></a> [rancher2](#requirement\_rancher2) | 1.21.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_generate_kube_config"></a> [generate\_kube\_config](#module\_generate\_kube\_config) | ../../control-plane/modules/generate-kube-config | n/a |
| <a name="module_rke2-bulk-clusters"></a> [rke2-bulk-clusters](#module\_rke2-bulk-clusters) | ./rke2 | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | n/a | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"us-west-1"` | no |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | n/a | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | (Optional) Desired cluster name, if not set then one will be generated | `string` | `""` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | n/a | `string` | `null` | no |
| <a name="input_insecure_flag"></a> [insecure\_flag](#input\_insecure\_flag) | Flag used to determine if Rancher is using self-signed invalid certs (using a private CA) | `bool` | `false` | no |
| <a name="input_k8s_distribution"></a> [k8s\_distribution](#input\_k8s\_distribution) | The K8s distribution to use for setting up Rancher (k3s , rke1, or rke2) | `string` | n/a | yes |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | Version of rke2 to use for downstream cluster | `string` | `"v1.21.10+rke2r2"` | no |
| <a name="input_rancher_api_url"></a> [rancher\_api\_url](#input\_rancher\_api\_url) | api url for rancher server | `string` | n/a | yes |
| <a name="input_rancher_token_key"></a> [rancher\_token\_key](#input\_rancher\_token\_key) | rancher server API token | `string` | n/a | yes |
| <a name="input_roles_per_pool"></a> [roles\_per\_pool](#input\_roles\_per\_pool) | A list of maps where each element contains keys that define the roles and quantity for a given node pool.<br>  Example: [<br>    {<br>      "quantity" = 3<br>      "etd" = true<br>      "control-plane" = true<br>      "worker" = true<br>    }<br>  ] | `list(map(string))` | n/a | yes |
| <a name="input_scale_aws_cloud_creds"></a> [scale\_aws\_cloud\_creds](#input\_scale\_aws\_cloud\_creds) | n/a | `bool` | `false` | no |
| <a name="input_scale_linode_cloud_creds"></a> [scale\_linode\_cloud\_creds](#input\_scale\_linode\_cloud\_creds) | n/a | `bool` | `false` | no |
| <a name="input_scale_projects"></a> [scale\_projects](#input\_scale\_projects) | n/a | `bool` | `false` | no |
| <a name="input_scale_secrets"></a> [scale\_secrets](#input\_scale\_secrets) | n/a | `bool` | `false` | no |
| <a name="input_scale_secretsv2"></a> [scale\_secretsv2](#input\_scale\_secretsv2) | n/a | `bool` | `false` | no |
| <a name="input_scale_tokens"></a> [scale\_tokens](#input\_scale\_tokens) | n/a | `bool` | `false` | no |
| <a name="input_scale_users"></a> [scale\_users](#input\_scale\_users) | n/a | `bool` | `false` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | A list of security group names (EC2-Classic) or IDs (default VPC) to associate with | `list(any)` | `[]` | no |
| <a name="input_server_instance_type"></a> [server\_instance\_type](#input\_server\_instance\_type) | Instance type to use for rke2 server | `string` | n/a | yes |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Size of the storage volume to use in GB | `string` | `"32"` | no |
| <a name="input_volume_type"></a> [volume\_type](#input\_volume\_type) | Type of storage volume to use | `string` | `"gp2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws-cloud-creds-cluster"></a> [aws-cloud-creds-cluster](#output\_aws-cloud-creds-cluster) | n/a |
| <a name="output_kube-configs"></a> [kube-configs](#output\_kube-configs) | n/a |
| <a name="output_projects-cluster"></a> [projects-cluster](#output\_projects-cluster) | n/a |
| <a name="output_secrets-cluster"></a> [secrets-cluster](#output\_secrets-cluster) | n/a |
| <a name="output_secretsv2-cluster"></a> [secretsv2-cluster](#output\_secretsv2-cluster) | n/a |
| <a name="output_tokens-cluster"></a> [tokens-cluster](#output\_tokens-cluster) | n/a |
| <a name="output_users-cluster"></a> [users-cluster](#output\_users-cluster) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
