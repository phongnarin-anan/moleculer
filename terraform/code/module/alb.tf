# Create the Application Load Balancer
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["${aws_subnet.public_subnet_1.id}", "${aws_subnet.public_subnet_2.id}"]

  enable_deletion_protection = false
  idle_timeout               = 60
}

# Create the Target Group for API Service
resource "aws_lb_target_group" "api_tg" {
  name     = "api-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create the Target Group for Service#1
resource "aws_lb_target_group" "service1_tg" {
  name     = "service1-target-group"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create the Target Group for Service#2
resource "aws_lb_target_group" "service2_tg" {
  name     = "service2-target-group"
  port     = 3002
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create the Target Group for NATS
resource "aws_lb_target_group" "nats_tg" {
  name     = "nats-target-group"
  port     = 4222
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create the Target Group for Obs
resource "aws_lb_target_group" "obs_tg" {
  name     = "obs-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create a listener for HTTP on the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Return form Public ALB"
      status_code  = "200"
    }
  }
}

# Create a listener for HTTPS on the ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.cert_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Return form Public ALB"
      status_code  = "200"
    }
  }
}

# Create listener rules for routing requests to target groups
resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api*"]
    }
  }
}

resource "aws_lb_listener_rule" "service1_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service1_tg.arn
  }

  condition {
    path_pattern {
      values = ["/service1*"]
    }
  }
}

resource "aws_lb_listener_rule" "service2_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service2_tg.arn
  }

  condition {
    path_pattern {
      values = ["/service2*"]
    }
  }
}


resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.obs_tg.arn
  }

  condition {
    path_pattern {
      values = [
        "/grafana*",
        "/grafana/*"
      ]
    }
  }
}
