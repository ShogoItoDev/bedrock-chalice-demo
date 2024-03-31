##### VPC Endpoints for Private Gateway.
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

output "private_api_gateway_vpce_id" {
  description = "VPC Endpoint ID of API Gateway."
  value       = aws_vpc_endpoint.execute-api.id
}

##### Optional - VPC Endpoints for SSM Session Manager.
resource "aws_vpc_endpoint" "ssm" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssm"
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

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
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

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
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