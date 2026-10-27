resource "aws_s3_bucket" "secure_storage" {
    bucket_prefix = "zenrak-secure-storage-"

    tags = {
        Project     = "Zenrak"
        Environment = "Learning"
        Purpose     = "Secure application storage"
    }
}


resource "aws_s3_bucket_versioning" "secure_storage" {
    bucket = aws_s3_bucket.secure_storage.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_security_group" "app" {
    name_prefix = "${var.project_name}-app-"
    description = "Security group for Zenrak Flask application"

    ingress {
        description = "HTTP for initial testing"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Project = var.project_name
    }
}

# Find a current Amazon Linux 2023 AMI in Mumbai

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name    = "name"
        values  = ["al2023-ami-2023.*x86_64"]
    }

    filter {
        name    = "architecture"
        values  = ["x86_64"]
    }

    filter {
        name    = "virtualization-type"
        values  = ["hvm"]
    }
}


# IAM role for the EC2 instance

resource "aws_iam_role" "app" {
    name = "${var.project_name}-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })

    tags = {
        Project = var.project_name
    }
}

resource "aws_iam_instance_profile" "app" {
    name = "${var.project_name}-instance-profile"
    role = aws_iam_role.app.name
}

## Persistent disk for application data

resource "aws_ebs_volume" "data" {
    availability_zone  = "${var.aws_region}a"
    size               = 8
    type               = "gp3"
    encrypted          = true

    tags = {
        Name    = "${var.project_name}-data"
        Project = var.project_name
    } 
}

# EC2 server

resource "aws_instance" "app" {
    ami                         = data.aws_ami.amazon_linux.id
    instance_type               = var.instance_type
    aws_iam_instance_profile    = aws_iam_instance_profile.app.name

    vpc_security_group_ids      = [aws_security_group.app.id]

    
}
