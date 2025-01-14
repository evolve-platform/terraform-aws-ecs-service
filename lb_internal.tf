resource "aws_lb_target_group" "internal" {
  count                         = var.enable_internal ? 1 : 0
  name                          = "${var.name}-internal"
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


resource "aws_lb_listener_rule" "internal" {
  count        = var.enable_internal ? 1 : 0
  listener_arn = data.aws_ssm_parameter.internal_listener_arn[0].value
  priority     = var.priority
  tags         = var.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal[0].arn
  }

  condition {
    host_header {
      values = [var.hostname_internal != "" ? var.hostname_internal : "${var.name}.*"]
    }
  }
}
