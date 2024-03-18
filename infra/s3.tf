resource "aws_s3_bucket" "default" {
  bucket = "bucket-${var.system_name}-${var.environment}"

}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// note: access to the bucket from Bedrock should be granted via bucket policy.
resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.bucket

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      },
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.default.arn}/*"
      ],
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
EOF
}