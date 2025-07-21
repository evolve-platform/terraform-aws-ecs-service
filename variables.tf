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
variable "proxy_vcpu" {
  type        = number
  description = "vCPU units for proxy"

  validation {
    condition     = var.proxy_vcpu >= 0.125 && var.proxy_vcpu <= 0.25
    error_message = "proxy_vcpu must be between 0.125 and 0.25 (vCPU)."
  }
  validation {
    condition     = var.proxy_vcpu % 0.125 == 0
    error_message = "proxy_vcpu must be a multiple of 0.125 (vCPU)."
  }

  default = 0.125
}

variable "proxy_memory_reservation_mib" {
  type        = number
  description = "Memory in MiB for proxy"

  validation {
    condition     = var.proxy_memory_reservation_mib >= 0.125 && var.proxy_memory_reservation_mib <= 2
    error_message = "proxy_memory_reservation_mib must be between 0.125 and 2 (MiB)."
  }

  default = 50
}

variable "proxy_memory_mib" {
  type        = number
  description = "Memory in MiB for proxy. If not set, it will be calculated by multiplying proxy_memory_reservation_mib by 2."
  nullable    = true

  validation {
    condition     = var.proxy_memory_mib >= var.proxy_memory_reservation_mib
    error_message = "proxy_memory_mib must be greater than or equal to proxy_memory_reservation_mib."
  }
}

variable "vcpu" {
  type        = number
  description = "vCPU units"
  nullable    = false

  validation {
    condition     = var.vcpu >= 0.125 && var.vcpu <= 2
    error_message = "vcpu must be between 0.125 and 0.25 (vCPU)."
  }

  validation {
    condition     = var.vcpu % 0.125 == 0
    error_message = "vcpu must be a multiple of 0.125 (vCPU)."
  }
}

variable "memory_reservation_gib" {
  type        = number
  description = "Memory reservation in GiB"
  nullable    = false

  validation {
    condition     = var.memory_reservation_gib >= 0.125 && var.memory_reservation_gib <= 2
    error_message = "memory_reservation_gib must be between 0.125 and 2 (GiB)."
  }

  validation {
    condition     = var.memory_reservation_gib % 0.125 == 0
    error_message = "memory_reservation_gib must be a multiple of 0.125 (GiB)."
  }
}

variable "memory_gib" {
  type        = number
  description = "Memory in GiB - hard limit. If not set, it will be calculated by multiplying memory_reservation_gib by 2."
  nullable    = true

  validation {
    condition     = var.memory_gib >= var.memory_reservation_gib
    error_message = "memory_gib must be greater than or equal to memory_reservation_gib."
  }
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks"
  nullable    = false

  validation {
    condition     = var.min_capacity >= 1
    error_message = "min_capacity must be at least 1."
  }

  validation {
    condition     = var.min_capacity <= var.max_capacity
    error_message = "min_capacity must be less than or equal to max_capacity."
  }
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks"
  nullable    = false

  validation {
    condition     = var.max_capacity >= 1
    error_message = "max_capacity must be at least 1."
  }
}

variable "desired_count" {
  type        = number
  description = "Number of desired tasks"
  nullable    = false

  validation {
    condition     = var.desired_count >= var.min_capacity && var.desired_count <= var.max_capacity
    error_message = "desired_count must be between min_capacity and max_capacity."
  }
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
  type = list(object({
    field = optional(string, null)
    type  = string
  }))
  default = [
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
