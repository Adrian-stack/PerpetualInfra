data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----- IAM role for EC2 -----
resource "aws_iam_role" "ec2_app" {
  name = "${var.name_prefix}-ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.name_prefix}-ec2-app-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "s3_uploads" {
  name = "${var.name_prefix}-s3-uploads"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3PhotoAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = var.s3_bucket_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm_params" {
  name = "${var.name_prefix}-ssm-params"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "SSMParamRead"
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      Resource = "arn:aws:ssm:${var.region}:*:parameter/perpetual-share/${var.environment}/*"
    }]
  })
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.name_prefix}-cw-logs"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CloudWatchLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:${var.region}:*:log-group:/perpetual-share/${var.environment}/*"
    }]
  })
}

resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.name_prefix}-ecr-pull"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ECRPull"
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = "*"
    }]
  })
}

# SSM Session Manager (no SSH needed)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.name_prefix}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name
}

# ----- EC2 instance -----
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_app.name

  user_data = base64encode(templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    region              = var.region
    environment         = var.environment
    s3_bucket           = var.s3_bucket_name
    image_uri           = var.image_uri
    cloudwatch_log_group = "/perpetual-share/${var.environment}/app"
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.name_prefix}-app"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = {
    Name        = "${var.name_prefix}-eip"
    Environment = var.environment
  }
}

# ----- Data EBS volume (SQLite) -----
resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.name_prefix}-data"
    Environment = var.environment
  }
}

resource "aws_volume_attachment" "data" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.data.id
  instance_id  = aws_instance.app.id
  force_detach = false
}
