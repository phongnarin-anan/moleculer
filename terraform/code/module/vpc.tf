# Data source to get availability zones
data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc"
  }
}

# Create subnets for private resources
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone       = element(data.aws_availability_zones.available.names, 1)
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-2"
  }
}

# Create subnets for public resources
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 3)
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 4)
  availability_zone       = element(data.aws_availability_zones.available.names, 1)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gateway"
  }
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# Create a NAT Gateway in the first public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "main-nat-gateway"
  }
}

# Create a private route table and associate with the private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate the route table with the private subnets
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create a public route table and associate with the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id # Route traffic to Internet Gateway
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a VPC endpoint for S3 in the private subnets
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name = "s3-endpoint"
  }
}

# Create a VPC endpoint for Secrets Manager in the private subnets
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids        = ["${aws_subnet.private_subnet_1.id}", "${aws_subnet.private_subnet_2.id}"]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "secrets-manager-endpoint"
  }
}

# Create a VPC endpoint for SNS in the private subnets
resource "aws_vpc_endpoint" "sns" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type = "Interface"
  subnet_ids        = ["${aws_subnet.private_subnet_1.id}", "${aws_subnet.private_subnet_2.id}"]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "sns-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_route_table.private_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_1_id" {
  value = aws_subnet.private_subnet_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "secrets_manager_endpoint_id" {
  value = aws_vpc_endpoint.secrets_manager.id
}
