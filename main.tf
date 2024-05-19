# main.tf

provider "aws" {
  region  = "sa-east-1"
}

resource "aws_instance" "example_server" {
  ami           = "ami-0cdc2f24b2f67ea17"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
  #!/bin/bash
     sudo apt update -y
     sudo apt install apache2 -y
     sudo systemctl start apache2
     sudo bash -c 'echo Hello World > /var/www/html/index.html'
     EOF

  user_data_replace_on_change = true

  tags = {
    Name = "UbuntuTeste"
  }

}

resource "aws_security_group" "instance" {
	name = "teste_servidor"
	ingress {
		from_port = 80
		to_port = 80
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


