variable "bucket_name" {
  type = string
}
variable "retention_days" {
  type = number
}
variable "statements" {
  type = any
}
resource "aws_s3_bucket" "evidence" {
  bucket              = var.bucket_name
  object_lock_enabled = true
  force_destroy       = false
  lifecycle { prevent_destroy = true }
}
resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket                  = aws_s3_bucket.evidence.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_ownership_controls" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule { object_ownership = "BucketOwnerEnforced" }
}
resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}
resource "aws_s3_bucket_object_lock_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.retention_days
    }
  }
  depends_on = [aws_s3_bucket_versioning.evidence]
}
resource "aws_s3_bucket_policy" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  policy = jsonencode({ Version = "2012-10-17", Statement = concat([
    { Sid = "DenyPlaintextTransport", Effect = "Deny", Principal = "*", Action = "s3:*", Resource = ["arn:aws:s3:::${var.bucket_name}", "arn:aws:s3:::${var.bucket_name}/*"], Condition = { Bool = { "aws:SecureTransport" = "false" } } }
  ], var.statements) })
}
output "name" { value = aws_s3_bucket.evidence.id }
output "arn" { value = aws_s3_bucket.evidence.arn }
output "policy" { value = aws_s3_bucket_policy.evidence.policy }

output "retention_contract" {
  value = {
    mode          = aws_s3_bucket_object_lock_configuration.evidence.rule[0].default_retention[0].mode
    days          = aws_s3_bucket_object_lock_configuration.evidence.rule[0].default_retention[0].days
    versioning    = aws_s3_bucket_versioning.evidence.versioning_configuration[0].status
    public_block  = aws_s3_bucket_public_access_block.evidence.block_public_policy && aws_s3_bucket_public_access_block.evidence.restrict_public_buckets
    force_destroy = aws_s3_bucket.evidence.force_destroy
  }
}
