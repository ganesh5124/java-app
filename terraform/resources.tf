# Creating a New Key
resource "aws_key_pair" "Key-Pair" {

  # Name of the Key
  key_name = "MyKey"

  # Adding the SSH authorized key !
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLeBTi0KxMNtIm5JMzrYTld2gpcsfd6dqjryFQyyjkhhM6Y445lEZYcPL3oSSlc9Icd6hPmfOcAcgJ5bkYWlCFgwMCcFqzp6WtQjxKDdH4LLMypoQbQ5HPoNU+QiDSsrsUJp+uu9szB0py2SBEi7nw7hDKHGfjQfhvq4Ihdr3hJd/XymTMY+5A9uyHperhJgLzUAn85DV6M1EVODIxHIndwRUxegPhPQ0nX7ieT8KQqJwfTrwaoukOzctm1zt9y02lyMztderzyf6vpU9M4Oc1rWemt7qk2yYXvW8wRV0Y9KU0Pe1Z2ZMc9s6rFeoY/tg1uvJT9i0uKCzVb8FKjXxSbPw+LY4cUhWLR6Jgq7pixSO7GkAtASjAgf8KSwqOQ0Pku3n4/LseCeCcbwUB1HYDOvBf7notwoLdrWbuUdXrmypn6C9PLkZ1JEe8whhmT/x8t2l5q0taR/rLe3xD/MjSWyrNrAkADWpM5e4cKaOkFx/yMX1QkUS3zaE8SH6ojCU= Madhu Kiran@DESKTOP-I148625"

}

# Creating a VPC!
resource "aws_vpc" "demo" {

  # IP Range for the VPC
  cidr_block = "172.20.0.0/16"

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true
  tags = {
    Name = "demo"
  }
}


# Creating Public subnet!
resource "aws_subnet" "subnet1" {
  depends_on = [
    aws_vpc.demo
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.demo.id

  # IP Range of this subnet
  cidr_block = "172.20.10.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-1a"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

# Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.demo,
    aws_subnet.subnet1,
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "IG-Public-&-Private-VPC"
  }
}

# Creating an Route Table for the public subnet!
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.demo,
    aws_internet_gateway.Internet_Gateway
  ]

  # VPC ID
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "Route Table for Internet Gateway"
  }
}

# Creating a resource for the Route Table Association!
resource "aws_route_table_association" "RT-IG-Association" {

  depends_on = [
    aws_vpc.demo,
    aws_subnet.subnet1,
    aws_route_table.Public-Subnet-RT
  ]

  # Public Subnet ID
  subnet_id = aws_subnet.subnet1.id

  #  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}

# Creating a Security Group for Jenkins
resource "aws_security_group" "JENKINS-SG" {

  depends_on = [
    aws_vpc.demo,
    aws_subnet.subnet1,
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "jenkins-sg"

  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.demo.id

  # Created an inbound rule for webserver access!
  ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 8080

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating an AWS instance for the Jenkins!
resource "aws_instance" "jenkins" {

  depends_on = [
    aws_vpc.demo,
    aws_subnet.subnet1,
    aws_security_group.JENKINS-SG
  ]

  ami = "ami-0b5eea76982371e91"
  # amazoon-linux
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "MyKey"

  # Security groups to use!
  vpc_security_group_ids = [aws_security_group.JENKINS-SG.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install -y epel",
      "sudo yum install wget ",
      #    "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      #    "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum update -y",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo yum install jenkins -y",
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",
      "sudo yum install git maven -y",
      "sudo yum install ansible -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -aG docker $USER",
      "sudo usermod -aG docker jenkins",
      "sudo systemctl enable docker.service",
      "sudo systemctl enable containerd.service",
      "sudo service docker restart",
    ]
  }
  tags = {
    Name = "Jenkins_From_Terraform"
  }

}
