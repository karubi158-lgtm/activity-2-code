provider "aws" {
  region  = var.primary_region
  profile = "project"
}

provider "aws" {
  alias   = "singapore"
  region  = var.secondary_region
  profile = "project"
}
