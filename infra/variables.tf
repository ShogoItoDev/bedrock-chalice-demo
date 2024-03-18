variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "system_name" {
  type    = string
  default = "bedrock-app"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}