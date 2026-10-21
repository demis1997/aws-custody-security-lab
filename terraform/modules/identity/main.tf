variable "account_id" { type = string }
variable "name" {
  type = string
}
variable "operator_arns" {
  type = set(string)
}
resource "aws_iam_role" "runtime" {
  name                 = "${var.name}-runtime"
  max_session_duration = 3600
  assume_role_policy   = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_instance_profile" "runtime" {
  name = "${var.name}-runtime"
  role = aws_iam_role.runtime.name
}
resource "aws_iam_role" "operator" {
  name                 = "${var.name}-operator"
  max_session_duration = 3600
  assume_role_policy   = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { AWS = sort(tolist(var.operator_arns)) }, Action = "sts:AssumeRole", Condition = { Bool = { "aws:MultiFactorAuthPresent" = "true" } } }] })
}
# SSM access is deliberately not granted here: an operator who can open a shell
# can control a live signer. A separate reviewed break-glass attachment is required.
output "role_arn" { value = "arn:aws:iam::${var.account_id}:role/${aws_iam_role.runtime.name}" }
output "role_name" { value = aws_iam_role.runtime.name }
output "instance_profile" { value = aws_iam_instance_profile.runtime.name }
output "operator_trust" { value = aws_iam_role.operator.assume_role_policy }
