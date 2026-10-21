variable "name" {
  type = string
}
variable "admin_arns" {
  type = set(string)
}
variable "runtime_arn" {
  type = string
}
locals {
  key_policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Sid = "IndependentKeyAdministrators", Effect = "Allow", Principal = { AWS = sort(tolist(var.admin_arns)) }, Action = ["kms:DescribeKey", "kms:GetKeyPolicy", "kms:PutKeyPolicy", "kms:EnableKeyRotation", "kms:GetKeyRotationStatus", "kms:ListResourceTags", "kms:TagResource", "kms:UntagResource", "kms:UpdateKeyDescription", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"], Resource = "*" },
    { Sid = "ContextBoundEnvelopeProtection", Effect = "Allow", Principal = { AWS = var.runtime_arn }, Action = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"], Resource = "*", Condition = { StringEquals = { "kms:EncryptionContext:custody:domain" = var.name, "kms:EncryptionContext:custody:purpose" = "share-envelope" } } },
    { Sid = "RuntimeMetadata", Effect = "Allow", Principal = { AWS = var.runtime_arn }, Action = ["kms:DescribeKey"], Resource = "*" }
  ] })
}
resource "aws_kms_key" "envelope" {
  description             = "${var.name} envelope protection; does not execute MPC"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = local.key_policy
}
resource "aws_kms_alias" "envelope" {
  name          = "alias/${var.name}-envelope"
  target_key_id = aws_kms_key.envelope.key_id
}
output "arn" { value = aws_kms_key.envelope.arn }
output "policy" { value = local.key_policy }
