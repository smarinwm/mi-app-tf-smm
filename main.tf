provider "aws" {
  region = "us-east-1"  # Cambia la región según tu necesidad
}

resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Permite trafico HTTP y SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite acceso publico al puerto 80
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite SSH desde cualquier IP (ajusta esto para mayor seguridad)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami             = "ami-053a45fff0a704a47"  # AMI de Amazon Linux  (cambia segun la región)
  instance_type   = "t2.micro"
  #key_name        = aws_key_pair.deployer_key.key_name
  security_groups = [aws_security_group.app_sg.name]

 user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo amazon-linux-extras enable docker
            sudo yum install -y docker git  # Instalamos Git junto con Docker
            sudo service docker start
            sudo usermod -aG docker ec2-user
            
            # Instalar Docker Compose
            sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            
            # Clonar el repositorio de GitHub
            cd /home/ec2-user
            git clone https://github.com/jorloque/mi-app-tf.git
            cd mi-app-tf
            
            # Construir y ejecutar el contenedor Docker
            docker build -t mi-aplicacion .
            docker run -d -p 80:80 mi-aplicacion
            EOF


  tags = {
    Name = "AppServer"
  }
}
output "public_ip" {
  value = aws_instance.app_server.public_ip
}
