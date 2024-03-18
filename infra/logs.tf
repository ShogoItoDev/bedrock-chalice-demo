resource "aws_cloudwatch_log_group" "default" {
  name              = "/aws/bedrock/${var.system_name}-${var.environment}/"
  retention_in_days = "90"

}