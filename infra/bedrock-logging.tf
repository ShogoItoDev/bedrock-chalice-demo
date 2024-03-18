resource "aws_bedrock_model_invocation_logging_configuration" "default" {


  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = true
    text_data_delivery_enabled      = true

    s3_config {
      bucket_name = aws_s3_bucket.default.id
      key_prefix  = "bedrock"
    }

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.default.name
      role_arn       = aws_iam_role.custom-bedrock-role.arn

      large_data_delivery_s3_config {
        bucket_name = aws_s3_bucket.default.id
        key_prefix  = "bedrock-large-data"
      }
    }
  }
}