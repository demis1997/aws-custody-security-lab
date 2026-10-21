variable "name" {
  type = string
}
variable "target_ou_id" {
  type = string
}
resource "aws_organizations_policy" "guardrail" {
  name = "${var.name}-custody-guardrail"
  type = "SERVICE_CONTROL_POLICY"
  content = jsonencode({ Version = "2012-10-17", Statement = [
    { Sid = "ProtectAudit", Effect = "Deny", Action = ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail", "guardduty:DeleteDetector", "guardduty:UpdateDetector"], Resource = "*" },
    { Sid = "BlockUnreviewedDelegation", Effect = "Deny", Action = ["organizations:LeaveOrganization", "iam:CreateUser", "iam:CreateAccessKey"], Resource = "*" }
  ] })
}
resource "aws_organizations_policy_attachment" "guardrail" {
  policy_id = aws_organizations_policy.guardrail.id
  target_id = var.target_ou_id
}
# This is a separately operated Organizations root. SCPs do not constrain
# management-account principals and management can remove these attachments.
