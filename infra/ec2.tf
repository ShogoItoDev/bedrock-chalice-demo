resource "aws_instance" "default" {
  ami                         = "ami-031134f7a79b6e424" # Amazon Linux 2023
  instance_type               = "t3.xlarge"
  subnet_id                   = aws_subnet.default[0].id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default.id]
  iam_instance_profile        = aws_iam_instance_profile.custom-ec2-instance-profile.id

  tags = {
    Name = "ec2-bedrock-api-client"
  }
}