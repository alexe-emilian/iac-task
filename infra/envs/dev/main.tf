terraform {
  # Provider definition is inherited from ../../providers.tf
  # Remote‑state backend injected via `terraform init -backend-config=backend.hcl`
}

################################################################################
# 1) Networking – create and tag our own production‑grade VPC
################################################################################

module "network" {
  source  = "../../modules/vpc"
  project = var.project
  env     = var.env
  cidr_block = "10.0.${var.env == "dev" ? 0 : 1}.0/24"  # dev → 10.0.0.0/24, prod → 10.0.1.0/24
  tags    = local.tags
}

################################################################################
# 2) Common tag map (provider default adds Creator/Project)
################################################################################

locals {
  tags = {
    Creator = "emilian"
    Project = "iac-task"
    Environment = var.env
  }
}

################################################################################
# 3) Modules – ECR → ALB → ECS service
################################################################################

module "ecr" {
  source  = "../../modules/ecr"
  project = var.project
  env     = var.env
  tags    = merge(local.tags, {})
}

module "alb" {
  source            = "../../modules/alb"
  project           = var.project
  env               = var.env
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  tags              = merge(local.tags, {})
}

module "service" {
  source              = "../../modules/ecs_service"
  project             = var.project
  env                 = var.env
  cpu                 = var.cpu
  memory              = var.memory
  desired_count       = var.desired_count
  image_uri           = "${module.ecr.repository_url}:${var.image_tag}"
  image_tag           = var.image_tag
  log_level           = var.log_level
  greeting_message    = var.greeting_message
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  target_group_arn    = module.alb.target_group_arn
  alb_sg_id           = module.alb.alb_sg_id
  log_group_prefix    = var.log_group_prefix
  tags                = merge(local.tags, {})
}

################################################################################
# 4) Outputs – helpful for CI logs & README
################################################################################

output "alb_dns" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "service_name" {
  description = "ECS service resource name (dev)"
  value       = module.service.service_name
}

output "repository_url" {
  description = "ECR URI for this environment (use for docker tag/push)"
  value       = module.ecr.repository_url
}