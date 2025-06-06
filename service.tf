

resource "aws_security_group" "primary" {
  count = var.network_mode == "awsvpc" ? 1 : 0

  name        = "${var.name}-ecs-service"
  description = "${var.name} security group"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "primary" {
  name                               = var.name
  cluster                            = local.cluster_id
  task_definition                    = aws_ecs_task_definition.container.arn
  desired_count                      = var.min_capacity
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  wait_for_steady_state              = false
  health_check_grace_period_seconds  = 60
  tags                               = var.tags

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "load_balancer" {
    for_each = var.enable_internal ? [true] : []
    content {
      target_group_arn = aws_lb_target_group.internal[0].arn
      container_name   = "proxy"
      container_port   = 8080
    }
  }

  dynamic "load_balancer" {
    for_each = var.enable_public ? [true] : []
    content {
      target_group_arn = aws_lb_target_group.public[0].arn
      container_name   = "proxy"
      container_port   = 8080
    }
  }

  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [true] : []
    content {
      subnets          = var.subnet_ids
      security_groups  = [aws_security_group.primary[0].id]
      assign_public_ip = false
    }
  }

  # Conditionally add service_connect_configuration if service_discovery is
  # specified
  dynamic "service_connect_configuration" {
    for_each = var.service_connect != null ? [var.service_connect] : []
    content {
      enabled   = true
      namespace = service_connect_configuration.value.namespace

      service {
        port_name      = "proxy"
        discovery_name = service_connect_configuration.value.discovery_name

        client_alias {
          port     = 8080
          dns_name = service_connect_configuration.value.dns_name
        }
      }

      log_configuration {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}-service-connect"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "service-connect"
        }
      }
    }
  }


  lifecycle {
    ignore_changes = [desired_count, capacity_provider_strategy]
  }
}

resource "aws_appautoscaling_target" "primary" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.primary.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags               = var.tags

  depends_on = [
    aws_ecs_service.primary
  ]
}

resource "aws_appautoscaling_policy" "primary" {
  for_each = {
    for policy in var.autoscaling_policies : policy.metric_type => policy
  }

  name               = "${each.value.metric_type}-${aws_ecs_service.primary.name}"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.primary.service_namespace
  resource_id        = aws_appautoscaling_target.primary.resource_id
  scalable_dimension = aws_appautoscaling_target.primary.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.metric_type
    }

    target_value       = each.value.target_value
    scale_in_cooldown  = each.value.scale_in_cooldown
    scale_out_cooldown = each.value.scale_out_cooldown
  }
}

resource "aws_appautoscaling_scheduled_action" "this" {
  for_each = { for k, v in var.autoscaling_scheduled_actions : k => v }

  name               = try(each.value.name, each.key)
  service_namespace  = aws_appautoscaling_target.primary.service_namespace
  resource_id        = aws_appautoscaling_target.primary.resource_id
  scalable_dimension = aws_appautoscaling_target.primary.scalable_dimension

  scalable_target_action {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }

  schedule   = each.value.schedule
  start_time = try(each.value.start_time, null)
  end_time   = try(each.value.end_time, null)
  timezone   = try(each.value.timezone, null)
}