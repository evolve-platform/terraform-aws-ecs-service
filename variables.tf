variable "name" {
  type        = string
  description = "Name of the service"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster (DEPCRECATED, use `cluster_id`)"
  default     = ""
}

variable "cluster_id" {
  type        = string
  description = "ID of the cluster"
  default     = ""
}

variable "hostname_internal" {
  type        = string
  description = "Internal hostname (supports wildcards)"
}

variable "hostname_public" {
  type        = string
  description = "Internal hostname (supports wildcards)"
  default     = ""
}

variable "image" {
  type = object({
    registry_id = string
    name        = string
    tag         = string
  })
  default = {
    registry_id = ""
    name        = ""
    tag         = ""
  }
  description = "Version to deploy"
}

variable "env_name" {
  type        = string
  description = "name of the environment"
}

variable "env_vars" {
  type        = any
  default     = {}
  description = "values to be passed to the container as environment variables"
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "values to be passed to the container as secrets"
}

variable "proxy_env_vars" {
  type        = any
  default     = {}
  description = "values to be passed to the reverse proxy as environment variables"
}

variable "proxy_image" {
  type = object({
    registry_id = string
    name        = string
    tag         = string
  })
  default = {
    registry_id = ""
    name        = "reverse-proxy"
    tag         = "latest"
  }
  description = "Version of the reverse proxy to deploy"
}

variable "enable_internal" {
  type        = bool
  description = "Whether to enable internal access"
  default     = false
}

variable "internal_listener_arn" {
  type        = string
  description = "ARN of the internal listener"
  default     = ""
}

variable "enable_public" {
  type        = bool
  description = "Whether to enable public access"
  default     = false
}

variable "public_listener_arn" {
  type        = string
  description = "ARN of the public listener"
  default     = ""
}

variable "priority" {
  type        = number
  description = "Priority of the rule"
  default     = 1
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "cpu" {
  type        = number
  description = "CPU units"
  default     = 128
}

variable "proxy_cpu" {
  type        = number
  description = "CPU units for proxy"
  default     = 128
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs"
  default     = []
}

variable "desired_count" {
  type        = number
  description = "Number of desired tasks"
  default     = 1
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 512
}

variable "proxy_memory" {
  type        = number
  description = "Memory in MB for proxy"
  default     = 32
}

variable "memory_reservation" {
  type        = number
  description = "Memory reservation in MB"
  default     = 256
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks"
  default     = 1
}

variable "fargate" {
  type        = bool
  description = "Whether to use Fargate"
  default     = false
}

variable "network_mode" {
  type        = string
  description = "Network mode"
  default     = "bridge"

  validation {
    condition     = contains(["bridge", "host", "awsvpc", "none"], var.network_mode)
    error_message = "network_mode must be one of 'bridge', 'host', 'awsvpc', or 'none'."
  }
}

variable "healthcheck" {
  type = object({
    path                = string
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout             = number
    matcher             = string
    interval            = number
  })
  default = {
    path                = "/"
    healthy_threshold   = 1
    unhealthy_threshold = 3
    timeout             = 2
    matcher             = "200-499"
    interval            = 5
  }
  description = "Healthcheck configuration"
}

variable "number_of_policies" {
  type    = number
  default = 0
}

variable "policies" {
  type        = list(string)
  description = "IAM policiy to attach to the task role"
  default     = []
}

variable "policy_json" {
  type        = string
  description = "IAM policiy to attach to the task role"
  default     = null
}

variable "public_paths" {
  type        = list(string)
  description = "Public paths"
  default     = []
}

variable "public_headers" {
  type    = map(string)
  default = {}
}

variable "service_connect" {
  description = "Service connect configuration"
  type = object({
    namespace      = string
    discovery_name = string
    dns_name       = string
  })
  default = null

  # Works only with terraform > 1.9 (checking other variables)
  # validation {
  #   condition     = var.network_mode == "awsvpc" || var.service_connect == null
  #   error_message = "'service_connect' can only be configured when 'network_mode' is 'awsvpc'."
  # }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources created by this module"
  default     = {}
}

variable "ordered_placement_strategy" {
  description = "Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence"
  type        = list(object({
    field = optional(string, null)
    type  = string
  }))
  default     = [
    {
      field = "attribute:ecs.availability-zone"
      type  = "spread"
    },
    {
      field = "cpu"
      type  = "binpack"
    }
  ]
}

variable "autoscaling_policies" {
  type = list(object({
    metric_type        = string
    target_value       = number
    scale_in_cooldown  = optional(number, 300)
    scale_out_cooldown = optional(number, 60)
  }))
  description = "Service autoscaling policies (TargetTrackingScaling)"

  validation {
    condition     = alltrue([for policy in var.autoscaling_policies : contains(["ECSServiceAverageCPUUtilization", "ECSServiceAverageMemoryUtilization"], policy.metric_type)])
    error_message = "Only 'ECSServiceAverageCPUUtilization' or 'ECSServiceAverageMemoryUtilization' are currently supported."
  }

  validation {
    condition     = alltrue([for policy in var.autoscaling_policies : policy.target_value >= 0 && policy.target_value <= 100])
    error_message = "target_value must be between 0 and 100."
  }

  default = [{
    metric_type  = "ECSServiceAverageCPUUtilization"
    target_value = 70
  }]
}

variable "autoscaling_scheduled_actions" {
  type = map(object({
    name         = optional(string, null)
    min_capacity = number
    max_capacity = number
    schedule     = string
    start_time   = optional(string, null)
    end_time     = optional(string, null)
  }))
  description = "Service autoscaling scheduled actions"
  default     = {}
}