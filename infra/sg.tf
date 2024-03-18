resource "aws_security_group" "default" {
  name   = "${var.system_name}-${var.environment}-sg"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.system_name}-${var.environment}-sg"
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

}
