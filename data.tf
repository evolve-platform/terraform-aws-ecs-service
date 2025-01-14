data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "public_listener_arn" {
  count = var.enable_public ? 1 : 0
  name  = "/platform/lb-public-listener-arn"
}

data "aws_ssm_parameter" "internal_listener_arn" {
  count = var.enable_internal ? 1 : 0
  name  = "/platform/lb-internal-listener-arn"
}

data "aws_ecs_cluster" "main" {
  cluster_name = var.cluster_name
}

data "aws_ecr_image" "server" {
  registry_id     = var.image.registry_id
  repository_name = var.image.name
  image_tag       = var.image.tag
}

data "aws_ecr_image" "proxy" {
  registry_id     = var.proxy_image.registry_id != "" ? var.proxy_image.registry_id : var.image.registry_id
  repository_name = var.proxy_image.name
  image_tag       = var.proxy_image.tag
}
