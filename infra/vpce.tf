resource "aws_vpc_endpoint" "execute-api" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.execute-api"
  subnet_ids = [
    aws_subnet.default.0.id,
    aws_subnet.default.1.id,
    aws_subnet.default.2.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.default.id
  ]
}