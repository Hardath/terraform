# main.tf

provider "aws" {
  region  = "sa-east-1"
}

variable "server_port" {
  description = "A porta que o servidor Web está usando"
  type        = number
  default     = 80
}

resource "aws_instance" "teste_servidor" {
  ami           = "ami-0af6e9042ea5a4e3e"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  
  user_data = <<-EOF
  #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Hello World run on port ${var.server_port} > /var/www/html/index.html'
              EOF
  
  user_data_replace_on_change = true
  
  tags = {
    Name = "UbuntuTeste"
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

