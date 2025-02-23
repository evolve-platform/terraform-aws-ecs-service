resource "aws_lb_target_group" "public" {
  count = var.enable_public ? 1 : 0

  name                          = "${var.name}-public"
  port                          = 80
  protocol                      = "HTTP"
  target_type                   = var.network_mode == "awsvpc" ? "ip" : "instance"
  vpc_id                        = var.vpc_id
  deregistration_delay          = "10"
  load_balancing_algorithm_type = "least_outstanding_requests"
  tags                          = var.tags

  health_check {
    path                = var.healthcheck.path
    healthy_threshold   = var.healthcheck.healthy_threshold
    unhealthy_threshold = var.healthcheck.unhealthy_threshold
    timeout             = var.healthcheck.timeout
    matcher             = var.healthcheck.matcher
    interval            = var.healthcheck.interval
  }
}

resource "aws_lb_listener_rule" "public" {
  count = var.enable_public ? 1 : 0

  listener_arn = local.public_listener_arn
  priority     = var.priority
  tags         = var.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public[0].arn
  }

  dynamic "condition" {
    for_each = var.public_paths

    content {
      path_pattern {
        values = [condition.value]
      }
    }
  }

  dynamic "condition" {
    for_each = var.public_headers
    content {
      http_header {
        http_header_name = condition.key
        values           = [condition.value]
      }
    }
  }

  condition {
    host_header {
      values = [var.hostname_public != "" ? var.hostname_public : "${var.name}.*"]
    }
  }
}
