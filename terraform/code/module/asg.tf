data "template_file" "api_user_data" {
  template = file("../module/user-data/user-data-api.sh")
  vars = {
    ROUTE53_HOSTED_ZONE_ID = aws_route53_zone.private_zone.id
    SECRET_ID              = var.secret_id
  }
}

#### Node.js API
# Launch Template
resource "aws_launch_template" "api_template" {
  name_prefix            = "api-lt-"
  image_id               = var.nodejs_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(data.template_file.api_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 30
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Auto Scaling Group
resource "aws_autoscaling_group" "api_asg" {
  desired_capacity    = 1
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.api_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "api-instance"
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
}

#### Node.js Service1
data "template_file" "service1_user_data" {
  template = file("../module/user-data/user-data-service1.sh")
  vars = {
    ROUTE53_HOSTED_ZONE_ID = aws_route53_zone.private_zone.id
    SECRET_ID              = var.secret_id
  }
}

# Launch Template
resource "aws_launch_template" "service1_template" {
  name_prefix            = "service1-lt-"
  image_id               = var.nodejs_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(data.template_file.service1_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 30
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Auto Scaling Group
resource "aws_autoscaling_group" "service1_asg" {
  desired_capacity    = 1
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.service1_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "service1-instance"
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
}

#### Node.js Service2
data "template_file" "service2_user_data" {
  template = file("../module/user-data/user-data-service2.sh")
  vars = {
    ROUTE53_HOSTED_ZONE_ID = aws_route53_zone.private_zone.id
    SECRET_ID              = var.secret_id
  }
}

# Launch Template
resource "aws_launch_template" "service2_template" {
  name_prefix            = "service2-lt-"
  image_id               = var.nodejs_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(data.template_file.service2_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 30
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Auto Scaling Group
resource "aws_autoscaling_group" "service2_asg" {
  desired_capacity    = 1
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.service2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "service2-instance"
    propagate_at_launch = true
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
}

#### NATS
data "template_file" "nats_user_data" {
  template = file("../module/user-data/user-data-nats.sh")
  vars = {
    ROUTE53_HOSTED_ZONE_ID = aws_route53_zone.private_zone.id
    SECRET_ID              = var.secret_id
    SNS_TOPIC_ARN          = aws_sns_topic.route53_topic.arn
    INSTANCE_TYPE          = "nats"
  }
}

# Launch Template
resource "aws_launch_template" "nats_template" {
  name_prefix            = "nats-lt-"
  image_id               = var.nats_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(data.template_file.nats_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 30
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "nats_asg" {
  desired_capacity    = 1
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.nats_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "nats-instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "0"
}

#### Obs
data "template_file" "obs_user_data" {
  template = file("../module/user-data/user-data-obs.sh")
  vars = {
    ROUTE53_HOSTED_ZONE_ID = aws_route53_zone.private_zone.id
    SECRET_ID              = var.secret_id
    SNS_TOPIC_ARN          = aws_sns_topic.route53_topic.arn
    INSTANCE_TYPE          = "obs"
    ACCOUNT_ID             = var.account_id
    REGION                 = var.region
  }
}

# Launch Template
resource "aws_launch_template" "obs_template" {
  name_prefix            = "obs-lt-"
  image_id               = var.obs_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(data.template_file.obs_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size           = 30
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Auto Scaling Group
resource "aws_autoscaling_group" "obs_asg" {
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.obs_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "obs-instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "0"
}

# Attach Node.js API ASG to ALB
resource "aws_autoscaling_attachment" "api_attachment" {
  autoscaling_group_name = aws_autoscaling_group.api_asg.name
  lb_target_group_arn    = aws_lb_target_group.api_tg.arn
}

# Attach Node.js Service1 ASG to ALB
resource "aws_autoscaling_attachment" "service1_attachment" {
  autoscaling_group_name = aws_autoscaling_group.service1_asg.name
  lb_target_group_arn    = aws_lb_target_group.service1_tg.arn
}

# Attach Node.js Service2 ASG to ALB
resource "aws_autoscaling_attachment" "service2_attachment" {
  autoscaling_group_name = aws_autoscaling_group.service2_asg.name
  lb_target_group_arn    = aws_lb_target_group.service2_tg.arn
}

# Attach NATS ASG to ALB
resource "aws_autoscaling_attachment" "nats_attachment" {
  autoscaling_group_name = aws_autoscaling_group.nats_asg.name
  lb_target_group_arn    = aws_lb_target_group.nats_tg.arn
}

# Attach Ops ASG to ALB
resource "aws_autoscaling_attachment" "ops_attachment" {
  autoscaling_group_name = aws_autoscaling_group.obs_asg.name
  lb_target_group_arn    = aws_lb_target_group.obs_tg.arn
}
