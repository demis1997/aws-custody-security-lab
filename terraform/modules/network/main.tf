variable "name" {
  type = string
}
variable "cidr" {
  type = string
}
variable "region" {
  type = string
}
variable "peer_cidrs" {
  type = set(string)
}
variable "rpc_proxy_cidrs" {
  type = set(string)
}
variable "accepted_peering_ids" {
  type = map(string)
}
variable "requested_peers" {
  type = map(object({ account_id = string, vpc_id = string, cidr = string }))
}
resource "aws_vpc" "domain" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}
resource "aws_default_security_group" "closed" {
  vpc_id  = aws_vpc.domain.id
  ingress = []
  egress  = []
}
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.domain.id
  cidr_block              = cidrsubnet(var.cidr, 4, 0)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-private" }
}
resource "aws_route_table" "private" { vpc_id = aws_vpc.domain.id }
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "workload" {
  name_prefix = "${var.name}-workload-"
  vpc_id      = aws_vpc.domain.id
  description = "Private mTLS workload; no SSH and no Internet default route"
}
resource "aws_security_group" "endpoints" {
  name_prefix = "${var.name}-endpoints-"
  vpc_id      = aws_vpc.domain.id
  description = "AWS API endpoints reachable only from workload security group"
}
resource "aws_vpc_security_group_ingress_rule" "api" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.workload.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}
resource "aws_vpc_security_group_egress_rule" "api" {
  security_group_id            = aws_security_group.workload.id
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}
resource "aws_vpc_security_group_ingress_rule" "mtls" {
  for_each          = var.peer_cidrs
  security_group_id = aws_security_group.workload.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 8443
  to_port           = 8443
}
resource "aws_vpc_security_group_egress_rule" "mtls" {
  for_each          = var.peer_cidrs
  security_group_id = aws_security_group.workload.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 8443
  to_port           = 8443
}
resource "aws_vpc_security_group_egress_rule" "rpc" {
  for_each          = var.rpc_proxy_cidrs
  security_group_id = aws_security_group.workload.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_endpoint" "api" {
  for_each            = toset(["ssm", "ssmmessages", "logs", "kms"])
  vpc_id              = aws_vpc.domain.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
}
resource "aws_vpc_peering_connection" "request" {
  for_each      = var.requested_peers
  vpc_id        = aws_vpc.domain.id
  peer_vpc_id   = each.value.vpc_id
  peer_owner_id = each.value.account_id
  auto_accept   = false
}
resource "aws_route" "request" {
  for_each                  = var.requested_peers
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.request[each.key].id
}
resource "aws_vpc_peering_connection_accepter" "accept" {
  for_each                  = var.accepted_peering_ids
  vpc_peering_connection_id = each.value
  auto_accept               = true
}
resource "aws_route" "accept" {
  for_each                  = var.accepted_peering_ids
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = each.key
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accept[each.key].id
}
output "subnet_id" { value = aws_subnet.private.id }
output "security_group_id" { value = aws_security_group.workload.id }
output "vpc_id" { value = aws_vpc.domain.id }
output "peering_requests" { value = { for k, v in aws_vpc_peering_connection.request : k => v.id } }

variable "recovery_bucket_name" { type = string }
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.domain.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  policy            = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = "*", Action = "s3:PutObject", Resource = "arn:aws:s3:::${var.recovery_bucket_name}/backups/${var.name}/*" }] })
}
resource "aws_vpc_security_group_egress_rule" "s3" {
  security_group_id = aws_security_group.workload.id
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
