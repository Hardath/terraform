# main.tf

provider "aws" {
  region  = "sa-east-1"
}

resource "aws_instance" "example_server" {
  ami           = "ami-0cdc2f24b2f67ea17"
  instance_type = "t2.micro"

  tags = {
    Name = "UbuntuTeste"
  }

}

