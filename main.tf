# main.tf

provider "aws" {
  region  = "sa-east-1"
}

variable "server_port" {
  description = "A porta do servidor web"
  type        = number
  default     = 80
}

resource "aws_launch_configuration" "teste_servidor" {
  image_id           = "ami-0af6e9042ea5a4e3e"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.alb.id]
  
  user_data = <<-EOF
  #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Hello World run on port ${var.server_port} > /var/www/html/index.html'
              EOF
              
  lifecycle {
		create_before_destroy = true
	}
  
}

data "aws_vpc" "default" {
   default = true
}

data "aws_subnets" "default" {
	filter { 
		name = "vpc-id"
		values = [data.aws_vpc.default.id]
	}
}

resource "aws_autoscaling_group" "teste_servidor" {
	launch_configuration = aws_launch_configuration.teste_servidor.name
	vpc_zone_identifier = data.aws_subnets.default.ids	
	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"
	
	min_size = 2
	max_size = 3
	tag {
		key = "Name"
		value = "terraform-asg-teste"
		propagate_at_launch = true
	}
}

resource "aws_security_group" "alb" {
	name = "teste_servidor_alb"
	ingress { 
		from_port = var.server_port
		to_port = var.server_port
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
  
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "teste" {
	name = "teste-terraform-asg-cluster"
	load_balancer_type = "application"
	subnets = data.aws_subnets.default.ids
	security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.teste.arn
	port = 80
	protocol = "HTTP"
	# By default, return a simple 404 page
	default_action {
		type = "fixed-response"
		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
		}
	}
}

resource "aws_lb_target_group" "asg" {
	name = "terraform-asg-teste"
	port = var.server_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id
	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 5
		timeout = 3
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
}

resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100
	condition {
		path_pattern {
			values = ["*"]
		}
	}
	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.asg.arn
	}
}

output "alb_dns_teste" {
	value = aws_lb.teste.dns_name
	description = "O DNS do load balancer"
}





