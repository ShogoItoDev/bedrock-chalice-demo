resource "aws_security_group" "default" {
  name   = "${var.system_name}-${var.environment}-sg"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.system_name}-${var.environment}-sg"
  }

  ##### Private API Gateway accepts inbound traffic from same security group on port 443/tcp.
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  ##### Optional - You need to allow outbound connection to the private API Gateway's security group on port 443/tcp.
  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

}
