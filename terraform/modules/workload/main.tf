variable "name" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "instance_profile" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "security_group_id" {
  type = string
}
variable "instance_type" {
  type = string
}
resource "aws_instance" "host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = var.instance_profile
  associate_public_ip_address = false
  monitoring                  = true
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  root_block_device {
    encrypted             = true
    volume_size           = 24
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = var.name, Purpose = "custody-security-lab", SoftwareState = "uninstalled" }
  # No curl|sh bootstrap, generated keys, or unattended MPC deployment.
}
output "instance_id" { value = aws_instance.host.id }

output "security_settings" {
  value = {
    public_ip   = aws_instance.host.associate_public_ip_address
    imds_tokens = aws_instance.host.metadata_options[0].http_tokens
    hop_limit   = aws_instance.host.metadata_options[0].http_put_response_hop_limit
    encrypted   = aws_instance.host.root_block_device[0].encrypted
  }
}
