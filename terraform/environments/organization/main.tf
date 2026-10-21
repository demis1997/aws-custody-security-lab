variable "target_ou_id" {
  type = string
}
module "guardrails" {
  source       = "../../modules/security-policies"
  name         = var.name
  target_ou_id = var.target_ou_id
}
