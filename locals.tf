locals {
  cluster_name = var.cluster_name == "" ? element(
    split("/", var.cluster_id),
    length(split("/", var.cluster_id)) - 1
  ) : var.cluster_name

  cluster_id = var.cluster_id != "" ? var.cluster_id : var.cluster_name

  registry_url = "${data.aws_ecr_image.proxy.registry_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}
