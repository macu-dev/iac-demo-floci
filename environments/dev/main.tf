module "demo" {
  source       = "../../stacks/demo-stack"
  environment  = "dev"
  project_name = "iac-floci"
}
