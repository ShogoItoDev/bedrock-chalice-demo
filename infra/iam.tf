##### Custom IAM Policy and Role to allow Bedrock invocation logging.
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


##### Optional - Custom IAM Role/Instance Profile to allow EC2 to be connected via SSM Session Manager.
resource "aws_iam_role" "custom-ec2-role" {
  name               = "custom-ec2-role"
  assume_role_policy = <<-EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "custom-ec2-attachment" {
  role       = aws_iam_role.custom-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# note: you need to explicitly create instance profile.
resource "aws_iam_instance_profile" "custom-ec2-instance-profile" {
  name = "custom-ec2-instance-profile"
  role = aws_iam_role.custom-ec2-role.name
}