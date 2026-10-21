variable "bucket_name" {
  type = string
}
variable "signer_runtime_arns" {
  type = map(string)
}
variable "checkpoint_publisher_arn" {
  type = string
}
variable "restore_reader_arns" {
  type = set(string)
}
locals {
  writer_statements = [for name, arn in var.signer_runtime_arns : { Sid = "Backup${replace(name, "-", "")}", Effect = "Allow", Principal = { AWS = arn }, Action = "s3:PutObject", Resource = "arn:aws:s3:::${var.bucket_name}/backups/${name}/*", Condition = { StringEquals = { "s3:x-amz-server-side-encryption" = "AES256" } } }]
}
module "recovery" {
  source         = "../../modules/evidence-store"
  bucket_name    = var.bucket_name
  retention_days = 30
  statements = concat(local.writer_statements, [
    { Sid = "IndependentCheckpointPublication", Effect = "Allow", Principal = { AWS = var.checkpoint_publisher_arn }, Action = "s3:PutObject", Resource = "arn:aws:s3:::${var.bucket_name}/checkpoints/*" },
    { Sid = "ReviewedRestoreRead", Effect = "Allow", Principal = { AWS = sort(tolist(var.restore_reader_arns)) }, Action = ["s3:GetObject", "s3:GetObjectVersion"], Resource = "arn:aws:s3:::${var.bucket_name}/*" }
  ])
}
output "bucket_name" { value = module.recovery.name }
output "bucket_policy" { value = module.recovery.policy }

output "retention_contract" { value = module.recovery.retention_contract }
