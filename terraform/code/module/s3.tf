# S3 Bucket
resource "aws_s3_bucket" "install_artifact" {
  bucket = "install-artifact" 

  # Optional configurations
  tags = {
    Name = "install-artifact"
  }
}

# Upload JavaScript file
resource "aws_s3_object" "js_folder" {
  bucket       = aws_s3_bucket.install_artifact.bucket
  key          = "js/"
  content_type = "application/x-directory"
  acl          = "private"
}

# Upload Shell Script file
resource "aws_s3_object" "sh_folder" {
  bucket       = aws_s3_bucket.install_artifact.bucket
  key          = "sh/"
  content_type = "application/x-directory"
  acl          = "private"
}