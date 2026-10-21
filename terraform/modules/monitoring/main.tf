variable "name" {
  type = string
}
variable "audit_bucket_name" {
  type = string
}
variable "runtime_role_name" {
  type = string
}
variable "region" {
  type = string
}
variable "account_id" {
  type = string
}
variable "enable_guardduty" {
  type = bool
}
resource "aws_cloudwatch_log_group" "workload" {
  name              = "/custody/${var.name}/workload"
  retention_in_days = 365
}
resource "aws_cloudwatch_log_group" "control_events" {
  name              = "/custody/${var.name}/control-events"
  retention_in_days = 365
}
resource "aws_cloudtrail" "domain" {
  name                          = var.name
  s3_bucket_name                = var.audit_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
}
resource "aws_guardduty_detector" "domain" {
  count                        = var.enable_guardduty ? 1 : 0
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
resource "aws_cloudwatch_event_rule" "control_changes" {
  name          = "${var.name}-authority-changes"
  event_pattern = jsonencode({ source = ["aws.iam", "aws.kms", "aws.cloudtrail"], "detail-type" = ["AWS API Call via CloudTrail"], detail = { eventName = ["PutKeyPolicy", "CreateGrant", "UpdateAssumeRolePolicy", "AttachRolePolicy", "PutRolePolicy", "StopLogging", "DeleteTrail"] } })
}
resource "aws_cloudwatch_event_target" "control_changes" {
  rule = aws_cloudwatch_event_rule.control_changes.name
  arn  = aws_cloudwatch_log_group.control_events.arn
}
resource "aws_cloudwatch_log_resource_policy" "events" {
  policy_name     = "${var.name}-eventbridge"
  policy_document = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "events.amazonaws.com" }, Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.control_events.arn}:*", Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.control_changes.arn }, StringEquals = { "aws:SourceAccount" = var.account_id } } }] })
}
resource "aws_iam_role_policy" "runtime_observability" {
  name = "${var.name}-observability"
  role = var.runtime_role_name
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.workload.arn}:*" },
    { Effect = "Allow", Action = ["ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"], Resource = "*" },
    { Effect = "Allow", Action = ["ssm:UpdateInstanceInformation"], Resource = "*" }
  ] })
}
output "log_group" { value = aws_cloudwatch_log_group.workload.name }

variable "vpc_id" { type = string }
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/custody/${var.name}/vpc-flow"
  retention_in_days = 365
}
resource "aws_iam_role" "flow" {
  name               = "${var.name}-vpc-flow"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" }, Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = var.account_id }, ArnLike = { "aws:SourceArn" = "arn:aws:ec2:${var.region}:${var.account_id}:vpc-flow-log/*" } } }] })
}
resource "aws_iam_role_policy" "flow" {
  name = "${var.name}-vpc-flow"
  role = aws_iam_role.flow.name
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"], Resource = "${aws_cloudwatch_log_group.flow.arn}:*" },
    { Effect = "Allow", Action = ["logs:DescribeLogGroups"], Resource = "*" }
  ] })
}
resource "aws_flow_log" "domain" {
  vpc_id          = var.vpc_id
  iam_role_arn    = aws_iam_role.flow.arn
  log_destination = aws_cloudwatch_log_group.flow.arn
  traffic_type    = "ALL"
  depends_on      = [aws_iam_role_policy.flow]
}
