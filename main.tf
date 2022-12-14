terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  profile = var.profile_name
}

# Server creation code
resource "aws_instance" "web-server-1" {
  ami           = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = var.iam_role
  key_name = var.instance_key
  subnet_id              = aws_subnet.public_subnet1.id
  security_groups = [aws_security_group.sg.id]

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install httpd -y
  sudo sed 's/80/8080/' /etc/httpd/conf/httpd.conf >> httpd.conf
  sudo rm -rf /etc/httpd/conf/httpd.conf
  sudo cp httpd.conf /etc/httpd/conf/
  sudo systemctl start httpd
  sudo systemctl enable httpd
  echo '<body style = "background:pink"><h1>Sample Web Application From Server 1</h1></body>' >> /var/www/html/index.html
  echo "*** Completed Installing apache2"
  EOF

  tags = {
    Name = "web_instance_1"
  }

  volume_tags = {
    Name = "web_instance_1"
  } 
}

resource "aws_instance" "web-server-2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = var.iam_role
  key_name = var.instance_key
  subnet_id              = aws_subnet.public_subnet2.id
  security_groups = [aws_security_group.sg.id]

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install httpd -y
  sudo sed 's/80/8080/' /etc/httpd/conf/httpd.conf >> httpd.conf
  sudo rm -rf /etc/httpd/conf/httpd.conf
  sudo cp httpd.conf /etc/httpd/conf/
  sudo systemctl start httpd
  sudo systemctl enable httpd
  echo '<body style = "background:pink"><h1>Sample Web Application From Server 2</h1></body>' >> /var/www/html/index.html
  echo "*** Completed Installing apache2"
  EOF

  tags = {
    Name = "web_instance_2"
  }

  volume_tags = {
    Name = "web_instance_2"
  } 
}

# AWS Loadbalancer creation code
resource "aws_lb" "web-app-alb" {
  name               = "web-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}

resource "aws_lb_target_group" "web-app-80-tg" {
  name     = "web-app-80-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
}

resource "aws_lb_target_group_attachment" "web-instance-80-1" {
  target_group_arn = aws_lb_target_group.web-app-80-tg.arn
  target_id        = aws_instance.web-server-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web-instance-80-2" {
  target_group_arn = aws_lb_target_group.web-app-80-tg.arn
  target_id        = aws_instance.web-server-2.id
  port             = 80
}


resource "aws_lb_target_group" "web-app-8080-tg" {
  name     = "web-app-8080-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
}

resource "aws_lb_target_group_attachment" "web-instance-8080-1" {
  target_group_arn = aws_lb_target_group.web-app-8080-tg.arn
  target_id        = aws_instance.web-server-1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "web-instance-8080-2" {
  target_group_arn = aws_lb_target_group.web-app-8080-tg.arn
  target_id        = aws_instance.web-server-2.id
  port             = 8080
}


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web-app-alb.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-app-8080-tg.arn
  }
}
