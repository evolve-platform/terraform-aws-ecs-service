# AWS ECS service Terraform module

Terraform module to manage an AWS ECS service.
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_scheduled_action.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_scheduled_action) | resource |
| [aws_appautoscaling_target.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.service_connect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.ecs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role__ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener_rule.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_image.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_image) | data source |
| [aws_ecr_image.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_image) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.internal_listener_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.public_listener_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscaling_policies"></a> [autoscaling\_policies](#input\_autoscaling\_policies) | Service autoscaling policies (TargetTrackingScaling) | <pre>list(object({<br/>    metric_type        = string<br/>    target_value       = number<br/>    scale_in_cooldown  = optional(number, 300)<br/>    scale_out_cooldown = optional(number, 60)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "metric_type": "ECSServiceAverageCPUUtilization",<br/>    "target_value": 70<br/>  }<br/>]</pre> | no |
| <a name="input_autoscaling_scheduled_actions"></a> [autoscaling\_scheduled\_actions](#input\_autoscaling\_scheduled\_actions) | Service autoscaling scheduled actions | <pre>map(object({<br/>    name         = optional(string, null)<br/>    min_capacity = number<br/>    max_capacity = number<br/>    schedule     = string<br/>    start_time   = optional(string, null)<br/>    end_time     = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID of the cluster | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster (DEPCRECATED, use `cluster_id`) | `string` | `""` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of desired tasks | `number` | n/a | yes |
| <a name="input_enable_internal"></a> [enable\_internal](#input\_enable\_internal) | Whether to enable internal access | `bool` | `false` | no |
| <a name="input_enable_public"></a> [enable\_public](#input\_enable\_public) | Whether to enable public access | `bool` | `false` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | name of the environment | `string` | n/a | yes |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | values to be passed to the container as environment variables | `any` | `{}` | no |
| <a name="input_fargate"></a> [fargate](#input\_fargate) | Whether to use Fargate | `bool` | `false` | no |
| <a name="input_healthcheck"></a> [healthcheck](#input\_healthcheck) | Healthcheck configuration | <pre>object({<br/>    path                = string<br/>    healthy_threshold   = number<br/>    unhealthy_threshold = number<br/>    timeout             = number<br/>    matcher             = string<br/>    interval            = number<br/>  })</pre> | <pre>{<br/>  "healthy_threshold": 1,<br/>  "interval": 5,<br/>  "matcher": "200-499",<br/>  "path": "/",<br/>  "timeout": 2,<br/>  "unhealthy_threshold": 3<br/>}</pre> | no |
| <a name="input_hostname_internal"></a> [hostname\_internal](#input\_hostname\_internal) | Internal hostname (supports wildcards) | `string` | n/a | yes |
| <a name="input_hostname_public"></a> [hostname\_public](#input\_hostname\_public) | Internal hostname (supports wildcards) | `string` | `""` | no |
| <a name="input_image"></a> [image](#input\_image) | Version to deploy | <pre>object({<br/>    registry_id = string<br/>    name        = string<br/>    tag         = string<br/>  })</pre> | <pre>{<br/>  "name": "",<br/>  "registry_id": "",<br/>  "tag": ""<br/>}</pre> | no |
| <a name="input_internal_listener_arn"></a> [internal\_listener\_arn](#input\_internal\_listener\_arn) | ARN of the internal listener | `string` | `""` | no |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | Maximum number of tasks | `number` | n/a | yes |
| <a name="input_memory_gib"></a> [memory\_gib](#input\_memory\_gib) | Memory in GiB - hard limit. If not set, it will be calculated by multiplying memory\_reservation\_gib by 2. | `number` | n/a | yes |
| <a name="input_memory_reservation_gib"></a> [memory\_reservation\_gib](#input\_memory\_reservation\_gib) | Memory reservation in GiB | `number` | n/a | yes |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | Minimum number of tasks | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the service | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode | `string` | `"bridge"` | no |
| <a name="input_number_of_policies"></a> [number\_of\_policies](#input\_number\_of\_policies) | n/a | `number` | `0` | no |
| <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy) | Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence | <pre>list(object({<br/>    field = optional(string, null)<br/>    type  = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "field": "attribute:ecs.availability-zone",<br/>    "type": "spread"<br/>  },<br/>  {<br/>    "field": "cpu",<br/>    "type": "binpack"<br/>  }<br/>]</pre> | no |
| <a name="input_policies"></a> [policies](#input\_policies) | IAM policiy to attach to the task role | `list(string)` | `[]` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | IAM policiy to attach to the task role | `string` | `null` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | Priority of the rule | `number` | `1` | no |
| <a name="input_proxy_env_vars"></a> [proxy\_env\_vars](#input\_proxy\_env\_vars) | values to be passed to the reverse proxy as environment variables | `any` | `{}` | no |
| <a name="input_proxy_image"></a> [proxy\_image](#input\_proxy\_image) | Version of the reverse proxy to deploy | <pre>object({<br/>    registry_id = string<br/>    name        = string<br/>    tag         = string<br/>  })</pre> | <pre>{<br/>  "name": "reverse-proxy",<br/>  "registry_id": "",<br/>  "tag": "latest"<br/>}</pre> | no |
| <a name="input_proxy_memory_mib"></a> [proxy\_memory\_mib](#input\_proxy\_memory\_mib) | Memory in MiB for proxy. If not set, it will be calculated by multiplying proxy\_memory\_reservation\_mib by 2. | `number` | n/a | yes |
| <a name="input_proxy_memory_reservation_mib"></a> [proxy\_memory\_reservation\_mib](#input\_proxy\_memory\_reservation\_mib) | Memory in MiB for proxy | `number` | `50` | no |
| <a name="input_proxy_vcpu"></a> [proxy\_vcpu](#input\_proxy\_vcpu) | vCPU units for proxy | `number` | `0.125` | no |
| <a name="input_public_headers"></a> [public\_headers](#input\_public\_headers) | n/a | `map(string)` | `{}` | no |
| <a name="input_public_listener_arn"></a> [public\_listener\_arn](#input\_public\_listener\_arn) | ARN of the public listener | `string` | `""` | no |
| <a name="input_public_paths"></a> [public\_paths](#input\_public\_paths) | Public paths | `list(string)` | `[]` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | values to be passed to the container as secrets | `map(string)` | `{}` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group IDs | `list(string)` | `[]` | no |
| <a name="input_service_connect"></a> [service\_connect](#input\_service\_connect) | Service connect configuration | <pre>object({<br/>    namespace      = string<br/>    discovery_name = string<br/>    dns_name       = string<br/>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_vcpu"></a> [vcpu](#input\_vcpu) | vCPU units | `number` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->