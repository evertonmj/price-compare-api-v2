#Definicao de providers e configuracoes gerais
#Aqui são definidos os providers obrigatórios além da versão do terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Região a ser utilizada
provider "aws" {
  region = "us-east-1"
}
####################

###********** Configuracoes de Rede ***********###
#Criacao de uma VPC (Virtual Private Cloud) e definição de CIDR
resource "aws_vpc" "web_server_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Subnet pública para a instancia EC2
resource "aws_subnet" "pc_api_public_subnet" {
  vpc_id     = aws_vpc.web_server_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

#Subnet privada para o banco de dados em zonda de disponibilidade a
resource "aws_subnet" "pc_api_private_subnet1" {
  vpc_id     = aws_vpc.web_server_vpc.id

  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"

}

#Subnet privada para o banco de dados em zona de disponibilidade b
resource "aws_subnet" "pc_api_private_subnet2" {
  vpc_id     = aws_vpc.web_server_vpc.id

  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1c"

}

# Internet gateway
resource "aws_internet_gateway" "pc_api_ig" {
  vpc_id = aws_vpc.web_server_vpc.id

  tags = {
    Name = "Internet Gateway for EC2-to-RDS VPC"
  }
}

# Tabela de roteamento publica
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.web_server_vpc.id
  tags = {
    Name = "pcapi - Public route_table"
  }
}

# Associacao de tabela de rotas a subnet publica
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.pc_api_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"  # This is the default route for internet-bound traffic
  gateway_id             = aws_internet_gateway.pc_api_ig.id
}

# Associacao de tabela de rotas a subnet publica

#private subnet associated with the subnet
resource "aws_route_table_association" "private_route_table_association1" {
  subnet_id      = aws_subnet.pc_api_private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association2" {
  subnet_id      = aws_subnet.pc_api_private_subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.web_server_vpc.id
  tags = {
    Name = "pcapi - private route_table"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "pc-api-rds-db-subnet-group"
  subnet_ids = [aws_subnet.pc_api_private_subnet1.id,aws_subnet.pc_api_private_subnet2.id ]  #if multi AZ add another subnet
}

###************** Security Groups***************###
#Aqui é feita a criação do Security Group e definição das regras de entrada (ingress) e saída (egress) da instãncia
resource "aws_security_group" "web_server_sg" {
  #Vinculacao deste security group a VPC criada acima
  vpc_id = aws_vpc.web_server_vpc.id
  name = "pc-api-web-server-sg"

  #Liberacao para acesso SSH
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks      = ["0.0.0.0/0"]

  }

  #Liberacao de acesso HTTP
  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks      = ["0.0.0.0/0"]
  }

  #Liberacao de acesso HTTPS
  ingress {
     protocol  = "tcp"
     from_port = 443
     to_port   = 443
     cidr_blocks      = ["0.0.0.0/0"]
  }

  #regra de saida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_db_sg" {
  name = "pc-api-rds-db-sg"
  vpc_id = aws_vpc.web_server_vpc.id
}

resource "aws_security_group" "sg_for_rds" {
  name        = "my-db-sg"
  vpc_id = aws_vpc.web_server_vpc.id
  ingress {
    from_port   = 3306  # MySQL port
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }
}

####
#### Criacao do banco de dados RDS
resource "aws_db_instance" "pc_db_01" {
  instance_class = "db.t3.micro"
  allocated_storage = 10
  db_name = "price_compare_db"
  engine = "mysql"
  engine_version = "8.0"
  username = "admin"
  password = "p4ssw0rd"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds_db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

# Criacao da instancia EC2
# Alem da criacao da instancia, e feita a configuracao de um web server utilizando o user_data
# Este e um recurso que permite a execucao de comandos durante o processo de criacao da instancia
# Neste caso e feita a instalacao de um ambiente para execucao de uma API python com flask e banco de dados RDS
resource "aws_instance" "web_server" {
    ami         = "ami-04b70fa74e45c3917" #imagem do ubuntu
    instance_type    = "t2.micro" #tipo da instancia
    security_groups = [aws_security_group.web_server_sg.id] #vinculacao ao security group criado acima
    subnet_id = aws_subnet.pc_api_public_subnet.id
    associate_public_ip_address = true
    count = 1
    user_data = <<EOF
#!/bin/bash
echo "Atualizando apt-get..."
sudo apt-get update
echo "Instalamdp dependencias..."
sudo apt-get install nginx python3 python3-pip git nginx python3-venv -y
echo "Criando ambiente Python..."
echo "Criando amb iente Python..."
python3 -m venv /home/ubuntu/web_server
source /home/ubuntu/web_server/bin/activate
echo "Instalando dependencias python..."
sudo pip install flask flask_restful jsoninify sqlalchemy pymysql
IP_CUR_EC2=$(curl http://checkip.amazonaws.com)
echo "IP publico da instancia"
#nginx conf
echo "Criando configuracao NGINX..."
echo "server {
listen 80;
listen [::]:80;
server_name $(echo $IP_CUR_EC2);

location / {
proxy_pass http://127.0.0.1:5000;
include proxy_params;
}
}" | sudo tee /etc/nginx/sites-enabled/pc-site
#restart nginx
echo "Reiniciando nginx..."
sudo systemctl restart nginx
echo "Instalacao concluida!"
EOF
    tags = {
        Name = "Ever Instance Test"
    }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_to_db" {
  security_group_id = aws_security_group.rds_db_sg.id  # RDS security group
  referenced_security_group_id = aws_security_group.web_server_sg.id # EC2 security group
  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
}


