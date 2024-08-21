# Create a security group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow inbound HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the security group for the instances
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow inbound HTTP traffic to instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "NodeJS API and Grafana port"
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "NodeJS Service1 port"
  }

  ingress {
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "NodeJS Service2 port"
  }

  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "Grafana Loki API port"
  }

  ingress {
    from_port   = 4222
    to_port     = 4222
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "NATS port"
  }

  ingress {
    from_port   = 6222
    to_port     = 6222
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "NATS clustering port"
  }

  ingress {
    from_port   = 8222
    to_port     = 8222
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "NATS http monitoring port"
  }

  ingress {
    from_port   = 9095
    to_port     = 9095
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "Grafana Loki Communication port"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "Prometheus dashboard port"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "Prometheus Node Exporter port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the security group for the vpc endpoint
resource "aws_security_group" "vpce_sg" {
  name        = "vpce-sg"
  description = "Allow inbound HTTPS traffic to vpc endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
