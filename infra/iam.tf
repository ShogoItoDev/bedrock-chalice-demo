resource "aws_iam_policy" "custom-bedrock-policy" {
  name = "custom-bedrock-policy"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.default.arn}:*"
      },
      #      {
      #        Action = [
      #          "s3:GetObject",
      #          "s3:PutObject",
      #          "s3:ListBucket"
      #        ]
      #        Effect = "Allow"
      #        Resource = [
      #          "${aws_s3_bucket.default.arn}",
      #          "${aws_s3_bucket.default.arn}/*"
      #       ]
      #      }
    ]
  })
}

resource "aws_iam_role" "custom-bedrock-role" {
  name               = "custom-bedrock-role"
  assume_role_policy = <<-EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }
  ]
}
EOT

}

resource "aws_iam_role_policy_attachment" "custom-bedrock-attachment" {
  role       = aws_iam_role.custom-bedrock-role.name
  policy_arn = aws_iam_policy.custom-bedrock-policy.arn
}