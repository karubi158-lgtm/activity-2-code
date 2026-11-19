
data "aws_caller_identity" "current" {}

module "mumbai_app" {
  source = "./modules/regional_app"

  providers = {
    aws = aws
  }

  project_name              = var.project_name
  region_name               = var.primary_region
  secondary_region_name     = var.secondary_region
  environment               = var.environment
  instance_type             = var.instance_type
  bucket_name               = local.primary_bucket_name
  secondary_bucket_name     = local.secondary_bucket_name
  vpc_cidr                  = "10.0.0.0/16"
  ec2_instance_profile_name = aws_iam_instance_profile.ec2_profile.name
}

module "singapore_app" {
  source = "./modules/regional_app"

  providers = {
    aws = aws.singapore
  }

  project_name              = var.project_name
  region_name               = var.secondary_region
  secondary_region_name     = var.primary_region
  environment               = var.environment
  instance_type             = var.instance_type
  bucket_name               = local.secondary_bucket_name
  secondary_bucket_name     = local.primary_bucket_name
  vpc_cidr                  = "10.1.0.0/16"
  ec2_instance_profile_name = aws_iam_instance_profile.ec2_profile.name
}
