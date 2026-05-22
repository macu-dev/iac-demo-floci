module "demo" {
  source       = "../../stacks/demo-stack"
  environment  = "dev"
  project_name = "iac-floci"
}

output "ecr_repository_url" {
  value = module.demo.ecr_repository_url
}
