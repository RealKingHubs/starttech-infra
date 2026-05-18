# -----------------------------
# DATA SOURCES
# -----------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# -----------------------------
# CLOUDWATCH LOG GROUP
# -----------------------------

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/starttech/backend"
  retention_in_days = 14
}

# -----------------------------
# ECR REPOSITORY
# -----------------------------

resource "aws_ecr_repository" "backend" {
  name = "${var.environment}-starttech-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

# -----------------------------
# IAM ROLE FOR EC2
# -----------------------------

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-starttech-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# -----------------------------
# CLOUDWATCH POLICY
# -----------------------------

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ECR ACCESS

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM ACCESS

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "parameter_store_access" {
  name = "${var.environment}-parameter-store-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]

        Resource = "*"
      }
    ]
  })
}

# -----------------------------
# INSTANCE PROFILE
# -----------------------------

resource "aws_iam_instance_profile" "backend" {
  name = "${var.environment}-backend-profile"
  role = aws_iam_role.ec2_role.name
}

# -----------------------------
# TARGET GROUP
# -----------------------------

resource "aws_lb_target_group" "backend" {
  name     = "${var.environment}-backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }
}

# -----------------------------
# APPLICATION LOAD BALANCER
# -----------------------------

resource "aws_lb" "backend" {
  name               = "${var.environment}-backend-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group]
  subnets         = var.public_subnets
}

# -----------------------------
# ALB LISTENER
# -----------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# -----------------------------
# LAUNCH TEMPLATE
# -----------------------------

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.environment}-backend"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.backend.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.backend_security_group]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode(file("${path.module}/userdata.sh"))

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.environment}-backend-instance"
    }
  }
}


# -----------------------------
# AUTO SCALING GROUP
# -----------------------------

resource "aws_autoscaling_group" "backend" {
  name = "${var.environment}-backend-asg"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  vpc_zone_identifier = var.private_subnets

  target_group_arns = [
    aws_lb_target_group.backend.arn
  ]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  health_check_type = "ELB"

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }

    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-backend"
    propagate_at_launch = true
  }
}
# -----------------------------
# CPU SCALING POLICY
# -----------------------------

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.environment}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70
  }
}