## EC2Role

# Create the IAM role
resource "aws_iam_role" "ec2_instance_role" {
  name = "EC2InstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS     = "arn:aws:iam::448049806923:root",
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Define a policy that grants access to the S3 bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "EC2S3AccessPolicy"
  description = "Policy to allow access to the install-artifact S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::install-artifact",
          "arn:aws:s3:::install-artifact/*"
        ]
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.ec2_instance_role.name
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_access_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_instance_role.name
}

# Attach the AmazonRoute53ReadOnlyAccess policy to the role
resource "aws_iam_role_policy_attachment" "route53_readonly_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess"
  role       = aws_iam_role.ec2_instance_role.name
}

# Attach the SecretsManagerReadWrite policy to the role
resource "aws_iam_role_policy_attachment" "secret_manager_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.ec2_instance_role.name
}

# Attach the AmazonEC2FullAccess policy to the role
resource "aws_iam_role_policy_attachment" "ec2_full_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.ec2_instance_role.name
}

# Attach the AmazonSNSFullAccess policy to the role
resource "aws_iam_role_policy_attachment" "sns_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  role       = aws_iam_role.ec2_instance_role.name
}

# Create an instance profile for the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceRole"
  role = aws_iam_role.ec2_instance_role.name
}

# Optional: Output the role ARN and instance profile name for reference
output "s3_role_arn" {
  value = aws_iam_role.ec2_instance_role.arn
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}
