# main.tf

provider "aws" {
  region  = "sa-east-1"
}

variable "server_port" {
  description = "A porta que o servidor Web está usando"
  type        = number
  default     = 80
}

resource "aws_launch_configuration" "teste_servidor" {
  image_id      = "ami-0af6e9042ea5a4e3e"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  
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
	
	min_size = 2
	max_size = 3
	tag {
		key = "Name"
		value = "terraform-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_security_group" "instance" {
	name = "teste_servidor"
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

