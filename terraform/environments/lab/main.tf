variable "kind" {
  type = string
  validation {
    condition     = contains(["signer", "coordinator", "authorization"], var.kind)
    error_message = "Invalid workload domain kind."
  }
}
variable "cidr" {
  type = string
  validation {
    condition     = can(cidrhost(var.cidr, 0)) && startswith(var.cidr, "10.") && try(tonumber(split("/", var.cidr)[1]) >= 16 && tonumber(split("/", var.cidr)[1]) <= 24, false)
    error_message = "Use a private lab VPC CIDR."
  }
}
variable "ami_id" {
  type = string
  validation {
    condition     = can(regex("^ami-[a-f0-9]{17}$", var.ami_id))
    error_message = "Supply a reviewed AMI from the selected region."
  }
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "operator_arns" {
  type = set(string)
  validation {
    condition     = length(var.operator_arns) > 0 && alltrue([for a in var.operator_arns : can(regex("^arn:aws:iam::[0-9]{12}:(role|user)/[^*]+$", a))])
    error_message = "Provide exact independent operator principals; no root or wildcard trust."
  }
}
variable "key_admin_arns" {
  type = set(string)
  validation {
    condition     = length(var.key_admin_arns) > 0 && alltrue([for a in var.key_admin_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/[^*]+$", a))])
    error_message = "Provide exact independent key administrator roles."
  }
}
variable "peer_cidrs" {
  type    = set(string)
  default = []
  validation {
    condition     = alltrue([for c in var.peer_cidrs : can(cidrhost(c, 0)) && startswith(c, "10.") && try(tonumber(split("/", c)[1]) >= 16, false)])
    error_message = "No Internet peer CIDR."
  }
}
variable "rpc_proxy_cidrs" {
  type    = set(string)
  default = []
  validation {
    condition     = alltrue([for c in var.rpc_proxy_cidrs : can(cidrhost(c, 0)) && startswith(c, "10.") && try(tonumber(split("/", c)[1]) >= 16, false)])
    error_message = "RPC requires explicit proxy ranges."
  }
}
variable "requested_peers" {
  validation {
    condition     = alltrue([for p in values(var.requested_peers) : contains(var.peer_cidrs, p.cidr) && p.account_id != var.account_id && can(regex("^[0-9]{12}$", p.account_id))])
    error_message = "Peering routes must match explicitly approved private peer ranges in another account."
  }
  type    = map(object({ account_id = string, vpc_id = string, cidr = string }))
  default = {}
}
variable "accepted_peering_ids" {
  validation {
    condition     = alltrue([for c in keys(var.accepted_peering_ids) : contains(var.peer_cidrs, c)])
    error_message = "Accepted peering routes must match explicitly approved private peer ranges."
  }
  type    = map(string)
  default = {}
}
variable "audit_bucket_name" {
  type = string
}
variable "recovery_bucket_name" {
  type = string
}
variable "enable_guardduty" {
  type    = bool
  default = true
}
module "network" {
  source               = "../../modules/network"
  recovery_bucket_name = var.recovery_bucket_name
  name                 = var.name
  region               = var.region
  cidr                 = var.cidr
  peer_cidrs           = var.peer_cidrs
  rpc_proxy_cidrs      = var.kind == "coordinator" ? var.rpc_proxy_cidrs : toset([])
  requested_peers      = var.requested_peers
  accepted_peering_ids = var.accepted_peering_ids
}
module "identity" {
  source        = "../../modules/identity"
  name          = var.name
  operator_arns = var.operator_arns
  account_id    = var.account_id
}
module "keys" {
  count       = var.kind == "signer" ? 1 : 0
  source      = "../../modules/key-protection"
  name        = var.name
  admin_arns  = var.key_admin_arns
  runtime_arn = module.identity.role_arn
}
module "workload" {
  source            = "../../modules/workload"
  name              = var.name
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  instance_profile  = module.identity.instance_profile
  subnet_id         = module.network.subnet_id
  security_group_id = module.network.security_group_id
}
module "monitoring" {
  source            = "../../modules/monitoring"
  vpc_id            = module.network.vpc_id
  name              = var.name
  region            = var.region
  account_id        = var.account_id
  audit_bucket_name = var.audit_bucket_name
  runtime_role_name = module.identity.role_name
  enable_guardduty  = var.enable_guardduty
}
# Write-only backup upload; restoring belongs to independent recovery roles.
resource "aws_iam_role_policy" "backup" {
  count  = var.kind == "signer" ? 1 : 0
  role   = module.identity.role_name
  name   = "${var.name}-backup-upload"
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["s3:PutObject"], Resource = "arn:aws:s3:::${var.recovery_bucket_name}/backups/${var.name}/*", Condition = { StringEquals = { "s3:x-amz-server-side-encryption" = "AES256" } } }] })
}
resource "aws_ebs_encryption_by_default" "domain" { enabled = true }
output "key_policy" { value = var.kind == "signer" ? module.keys[0].policy : null }
output "operator_trust" { value = module.identity.operator_trust }
output "vpc_id" { value = module.network.vpc_id }
output "peering_requests" { value = module.network.peering_requests }
output "runtime_arn" { value = module.identity.role_arn }
output "instance_id" { value = module.workload.instance_id }
output "backup_policy" { value = var.kind == "signer" ? aws_iam_role_policy.backup[0].policy : null }

output "host_security" { value = module.workload.security_settings }
