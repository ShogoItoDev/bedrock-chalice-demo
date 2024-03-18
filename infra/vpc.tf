resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.system_name}-${var.environment}"
  }
}


resource "aws_subnet" "default" {
  count = 3

  vpc_id            = aws_vpc.default.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)

  tags = {
    Name = "snet-${var.system_name}-${var.environment}-${var.availability_zones[count.index]}"
  }

}