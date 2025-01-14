resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name}-ecs-task-role"
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  dynamic "inline_policy" {
    for_each = var.policy_json != "" ? [var.policy_json] : []
    content {
      name   = "inline-policy"
      policy = inline_policy.value
    }
  }
}

resource "aws_iam_policy" "ecs_policy" {
  name = "ecs-policy-${var.name}"
  tags = var.tags
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "execute-api:Invoke"
        Resource = [
          "arn:aws:execute-api:${data.aws_region.current.name}:*:*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:${var.name}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.ecs_policy.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecs-execution-role"
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  dynamic "inline_policy" {
    for_each = length(var.secrets) > 0 ? [1] : []
    content {
      name = "inline-policy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "secretsmanager:GetSecretValue",
            ]
            Resource = values(var.secrets)
          }
        ]
      })
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role__ecr" {
  role       = aws_iam_role.ecs_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "policies" {
  count      = var.number_of_policies
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = var.policies[count.index]
}
