resource "aws_vpc" "demo-app-vpc" {
  tags = {
    Name = "demo-app-vpc"
  }
}

resource "aws_security_group" "demo-app-sg" {
  vpc_id = aws_vpc.demo-app-vpc.id
}

resource "aws_subnet" "demo-app-subnet" {
  availability_zone = "ap-south-1a"
  vpc_id            = aws_vpc.demo-app-vpc.id
}

resource "aws_instance" "demo-app" {
  ami                    = var.aws_ami
  instance_type          = var.aws_instance_type
  provider               = aws.ap-south
  key_name               = var.aws_key_name
  vpc_security_group_ids = [aws_security_group.demo-app-sg.id]
  tags = {
    Name : "demo-app"
  }
}
