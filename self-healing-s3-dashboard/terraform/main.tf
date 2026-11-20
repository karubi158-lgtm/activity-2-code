data "aws_caller_identity" "me" {
  provider = aws.a
}

locals {
  bucket_a = "${var.bucket_prefix}-${var.region_a}-${data.aws_caller_identity.me.account_id}"
  bucket_b = "${var.bucket_prefix}-${var.region_b}-${data.aws_caller_identity.me.account_id}-v2"
}

# Each node owns one bucket + one healer Lambda in its own region.
# Node A mirrors/heals from B and vice versa.
module "node_a" {
  source             = "./modules/mirror_node"
  providers          = { aws = aws.a }
  bucket_name        = local.bucket_a
  region             = var.region_a
  peer_bucket_name   = local.bucket_b
  peer_region        = var.region_b
  healing_enabled    = var.healing_enabled
  reconcile_schedule = var.reconcile_schedule
}

module "node_b" {
  source             = "./modules/mirror_node"
  providers          = { aws = aws.b }
  bucket_name        = local.bucket_b
  region             = var.region_b
  peer_bucket_name   = local.bucket_a
  peer_region        = var.region_a
  healing_enabled    = var.healing_enabled
  reconcile_schedule = var.reconcile_schedule
}
