module "s3_bucket" {
  source      = "../../modules/s3"
  bucket_name = "${var.environment}-${var.project_name}-bucket"
  tags        = local.common_tags
}

module "dynamodb_table" {
  source        = "../../modules/dynamodb"
  table_name    = "${var.environment}-${var.project_name}-table"
  hash_key_name = "id"
  tags          = local.common_tags
}

module "ecr_repo" {
  source          = "../../modules/ecr"
  repository_name = "${var.environment}-${var.project_name}-repo"
  tags            = local.common_tags
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
