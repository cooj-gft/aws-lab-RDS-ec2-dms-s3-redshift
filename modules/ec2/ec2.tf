
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

   filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "ec2_lab1_camilo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro" 
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  associate_public_ip_address = true # Permitir registro de ip publica para acceso por connect
  key_name                 = null

  user_data = <<-EOF
    #!/bin/bash
    # asegurar ec2-instance-connect para EC2 Instance Connect (consola)
    if ! command -v mssh >/dev/null 2>&1; then
      sudo dnf install -y ec2-instance-connect || true
    fi
    sudo dnf install -y wget
    wget https://dev.mysql.com/get/mysql80-community-release-el9-3.noarch.rpm
    sudo dnf install -y mysql80-community-release-el9-3.noarch.rpm
    sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
    sudo dnf update -y
    sudo dnf install -y mysql-community-server
  EOF

  tags = {
    Name = "lab1-ec2-camilo"
  }
}
