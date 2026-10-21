variable "bucket_name" {
  type = string
}
variable "trail_account_ids" {
  type = set(string)
}
variable "trail_names" {
  type = set(string)
}
locals {
  source_arns = flatten([for id in var.trail_account_ids : [for n in var.trail_names : "arn:aws:cloudtrail:${var.region}:${id}:trail/${n}"]])
}
module "audit" {
  source         = "../../modules/evidence-store"
  bucket_name    = var.bucket_name
  retention_days = 30
  statements = [
    { Sid = "CloudTrailAcl", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" }, Action = "s3:GetBucketAcl", Resource = "arn:aws:s3:::${var.bucket_name}", Condition = { ArnEquals = { "aws:SourceArn" = local.source_arns } } },
    { Sid = "CloudTrailDelivery", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" }, Action = "s3:PutObject", Resource = [for id in var.trail_account_ids : "arn:aws:s3:::${var.bucket_name}/AWSLogs/${id}/*"], Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }, ArnEquals = { "aws:SourceArn" = local.source_arns } } }
  ]
}
output "bucket_name" { value = module.audit.name }
output "bucket_policy" { value = module.audit.policy }

output "retention_contract" { value = module.audit.retention_contract }
