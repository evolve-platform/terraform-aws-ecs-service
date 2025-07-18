resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.name}"
  retention_in_days = 90
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "service_connect" {
  count = var.service_connect != null ? 1 : 0

  name              = "/ecs/${var.name}-service-connect"
  retention_in_days = 90
  tags              = var.tags
}

locals {
  proxy_cpu_units              = var.proxy_vcpu * 1024
  proxy_memory_reservation_mib = var.proxy_memory_reservation_mib
  proxy_memory_mib             = var.proxy_memory_mib == null ? var.proxy_memory_reservation_mib * 2 : var.proxy_memory_mib

  app_cpu_units              = var.vcpu * 1024
  app_memory_reservation_mib = var.memory_reservation_gib * 1024
  app_memory_mib             = var.memory_gib == null ? var.memory_reservation_gib * 2 * 1024 : var.memory_gib * 1024

  # When not running on Fargate, add additional environment variables.
  env_vars = var.fargate ? var.env_vars : merge(
    var.env_vars,
    {
      "AWS_REGION" = data.aws_region.current.name
    }
  )

  # Same for the reverse proxy container. Mostly used to pass opentelemetry
  # environment variables.
  proxy_env_vars = var.fargate ? var.proxy_env_vars : merge(
    var.proxy_env_vars,
    {
      "AWS_REGION" = data.aws_region.current.name
    }
  )
}

resource "aws_ecs_task_definition" "container" {
  family                   = var.name
  requires_compatibilities = var.fargate ? ["FARGATE"] : ["EC2"]
  tags                     = var.tags

  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  network_mode = var.network_mode

  # When we are not using Fargate, we allow the containers to use all CPU
  # capacity available on the instance.
  cpu = var.fargate ? local.app_cpu_units : null

  # When we are not using Fargate, we allow the containers to use all memory
  memory = var.fargate ? local.app_memory_mib : null

  container_definitions = jsonencode([
    {
      name = "app"

      image             = "${local.registry_url}/${data.aws_ecr_image.server.repository_name}:${data.aws_ecr_image.server.image_tag}"
      essential         = true
      cpu               = var.fargate ? local.app_cpu_units - local.proxy_cpu_units : local.app_cpu_units
      memory            = var.fargate ? local.app_memory_mib - local.proxy_memory_mib : local.app_memory_mib
      memoryReservation = local.app_memory_reservation_mib - local.proxy_memory_reservation_mib

      environment = [for k, v in local.env_vars : {
        name  = k
        value = v
        }
      ]

      secrets = [for k, v in var.secrets : {
        name      = k
        valueFrom = v
        }
      ]

      # When we are using bridge as network mode the containers are linked
      # together, so we don't need to expose the port.
      portMappings = var.network_mode != "bridge" ? [
        {
          name          = "app"
          containerPort = 4000
          hostPort      = 4000
        }
      ] : null

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "${var.name}-"
        }
      }
    },
    {
      name = "proxy"

      image             = "${local.registry_url}/${data.aws_ecr_image.proxy.repository_name}:${data.aws_ecr_image.proxy.image_tag}"
      essential         = true
      cpu               = local.proxy_cpu_units
      memoryReservation = local.proxy_memory_reservation_mib
      memory            = local.proxy_memory_mib

      environment = [for k, v in local.proxy_env_vars : {
        name  = k
        value = v
        }
      ]

      links = var.network_mode == "bridge" ? ["app"] : null

      portMappings = [
        {
          name          = "proxy"
          containerPort = 8080
          hostPort      = var.network_mode == "awsvpc" ? 8080 : null
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "${var.name}-"
        }
      }
    }
  ])
}
