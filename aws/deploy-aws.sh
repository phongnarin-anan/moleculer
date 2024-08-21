AWS_PROFILE=$1
ACCOUNT_ID=$2

### S3 Terraform State
aws s3api create-bucket --profile $AWS_PROFILE --bucket terraform-state-$ACCOUNT_ID --create-bucket-configuration LocationConstraint=ap-southeast-1

# Create the S3 IAM policy
aws iam create-policy --profile $AWS_PROFILE --policy-name S3AccessPolicy --policy-document file://aws/json/s3-access-policy.json

# Create terraform CodeBuild service role
aws iam create-role --profile $AWS_PROFILE --role-name CodeBuildServiceRole --assume-role-policy-document file://aws/json/s3-role-trust-policy.json

# Attach the S3 IAM policy to the CodeBuild service role
aws iam attach-role-policy --profile $AWS_PROFILE --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/S3AccessPolicy --role-name CodeBuildServiceRole

# Create the Terraform IAM policy
aws iam create-policy --profile $AWS_PROFILE --policy-name TerraformPowerUserAccess --policy-document file://aws/json/terraform-policy.json

# Create terraform CodeBuild service role
aws iam create-role --profile $AWS_PROFILE --role-name TerraformCodeBuildRole --assume-role-policy-document file://aws/json/terraform-role-trust-policy.json

# Attach the S3 IAM policy to the CodeBuild service role
aws iam attach-role-policy --profile $AWS_PROFILE --role-name TerraformCodeBuildRole --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/TerraformPowerUserAccess

# Create GitHub Self-Hosted Runners on AWS CodeBuild
aws codebuild create-project --name GitHubActionsRunnerMoleculerProject \
--source "type=GITHUB,location=https://github.com/phongnarin-anan/moleculer" \
--environment "type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_SMALL" \
--service-role arn:aws:iam::$ACCOUNT_ID:role/CodeBuildServiceRole \
--artifacts type=NO_ARTIFACTS \

# Create Webhook of WORKFLOW_JOB_QUEUED on AWS CodeBuild
aws codebuild create-webhook --project-name GitHubActionsRunnerMoleculerProject \
--filter-groups "[[{\"type\":\"EVENT\",\"pattern\":\"WORKFLOW_JOB_QUEUED\"}]]"

# Create IAM role for OIDC
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://aws/json/github-oidc.json