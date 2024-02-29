provider "aws" {

  region                  = var.region
}


# Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  
  instance_tenancy     = "default"
}

# Create IGW for internet connection 
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# Create Public Subnet for EC2
resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ1

}

resource "aws_subnet" "prod-subnet-public-2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ2

}



# Create Private subnet for RDS
resource "aws_subnet" "prod-subnet-private-2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ1

}

# Create second Private subnet for RDS
resource "aws_subnet" "prod-subnet-private-2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ2

}

# Creating Route table 
resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.prod-igw.id
  }
}

# Associating route tabe to public subnet
resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_route_table_association" "prod-crta-public-subnet-2" {
  subnet_id      = aws_subnet.prod-subnet-public-2.id
  route_table_id = aws_route_table.prod-public-crt.id
}



//security group for EC2

resource "aws_security_group" "ec2_allow_rule" {
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }
}


# Security group for RDS
resource "aws_security_group" "RDS_allow_rule" {
  vpc_id = aws_vpc.prod-vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ec2_allow_rule.id}"]
  }
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow ec2"
  }

}

# Create RDS Subnet group
resource "aws_db_subnet_group" "RDS_subnet_grp" {
  subnet_ids = ["${aws_subnet.prod-subnet-private-1.id}", "${aws_subnet.prod-subnet-private-2.id}"]
}

# Create RDS instance
resource "aws_db_instance" "wordpressdb" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.RDS_subnet_grp.id
  vpc_security_group_ids = ["${aws_security_group.RDS_allow_rule.id}"]
  db_name                = var.database_name
  username               = var.database_user
  password               = var.database_password
  skip_final_snapshot    = true
}

# change USERDATA varible value after grabbing RDS endpoint info
data "template_file" "dados-rds" {
  template = file("${path.module}/galaxy/group_vars/ref")
  vars = {
    db_username      = "${var.database_user}"
    db_user_password = "${var.database_password}"
    db_name_wp       = "${var.database_name}"
    db_RDS           = "${aws_db_instance.wordpressdb.endpoint}"
    ip_servidor      = "${aws_eip.eip.public_ip}"
  }
}

# inserindo IP do servidor como host do ansible
data "template_file" "hosts-correto" {
  template = file("${path.module}/galaxy/tests/hosts")
  vars = {
    ip_servidor      = "${aws_eip.eip.public_ip}"
  }
}

# Configurações de LB, TG e AE
resource "aws_lb" "loadBalancer" {
  name               = "lb-teste"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_allow_rule.id]
  subnets            = [aws_subnet.prod-subnet-public-1.id, aws_subnet.prod-subnet-public-2.id]
  depends_on         = [aws_internet_gateway.prod-igw]
}

resource "aws_lb_target_group" "targetGrou-lb" {
  name     = "tg-teste"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod-vpc.id
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.loadBalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetGrou-lb.arn
  }
}

# ASG with Launch template
resource "aws_launch_template" "ec2-correta" {
  name_prefix   = "ec2-correta"
  image_id      = var.ami # To note: AMI is specific for each region
  instance_type = var.instance_type
  key_name = var.KEY_NAME
  user_data     = filebase64("user_data.sh")

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.prod-subnet-public-1
    security_groups             = ["${aws_security_group.ec2_allow_rule.id}"]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Worpress-web" # Name for the EC2 instances
    }
  }
}

resource "aws_autoscaling_group" "group-AE" {
  # no of instances
  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  # Connect to the target group
  target_group_arns = [aws_lb_target_group.targetGrou-lb.arn]

  vpc_zone_identifier = [ # Creating EC2 instances in private subnet
    aws_subnet.prod-subnet-public-2.id
  ]

  launch_template {
    id      = aws_launch_template.ec2-correta.id
    version = "$Latest"
  }
}

# # Create EC2 ( only after RDS is provisioned)
# resource "aws_instance" "wordpressec2" {
#   ami             = var.ami
#   instance_type   = var.instance_type
#   subnet_id       = aws_subnet.prod-subnet-public-1.id
#   vpc_security_group_ids = ["${aws_security_group.ec2_allow_rule.id}"]
  
#   key_name = var.KEY_NAME
#   tags = {
#     Name = "Wordpress.web"
#   }

#   # this will stop creating EC2 before RDS is provisioned
#   depends_on = [aws_db_instance.wordpressdb]
# }

// Sends your public key to the instance
resource "aws_key_pair" "chave-ansible" {
  key_name   = var.KEY_NAME
  public_key = file(var.PUBLIC_KEY_PATH)
}

# creating Elastic IP for EC2
resource "aws_eip" "eip" {
  instance = aws_instance.wordpressec2.id

}

output "IP" {
  value = aws_eip.eip.public_ip
}
output "RDS-Endpoint" {
  value = aws_db_instance.wordpressdb.endpoint
}

output "INFO" {
  value = "AWS Resources and Wordpress has been provisioned. Go to http://${aws_eip.eip.public_ip}"
}

# Save Rendered playbook content to local file
resource "local_file" "dados-rds-file" {
  content = "${data.template_file.dados-rds.rendered}"
  filename = "./galaxy/group_vars/all.yaml"
}

# Criando Hosts correto
resource "local_file" "hosts-correto-file" {
  content = "${data.template_file.hosts-correto.rendered}"
  filename = "./galaxy/hosts.ini"
}

#resource "local_file" "dados-rds-file-2" {
#  filename = "./ansible/vars"
#  source   = "./ansible/group_vars/teste"
#}

resource "null_resource" "Wordpress_Installation_Waiting" {

triggers={
    ec2_id=aws_instance.wordpressec2.id,
    rds_endpoint=aws_db_instance.wordpressdb.endpoint
    
    }

/*   connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.PRIV_KEY_PATH)
    host        = aws_eip.eip.public_ip
  }





 # Run script to update python on remote client
  provisioner "remote-exec" { 
    inline = [
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install mysql-client -y",
      "sudo apt install unzip -y",
      "echo 'Concluído' && exit 0"
    ]
} */

# Play ansiblw playbook
provisioner "local-exec" {
  command = <<-EOT
    sleep 20
    ansible-playbook -u ubuntu -i ./galaxy/hosts.ini --private-key ./galaxy/chave-ansible.pem --ssh-common-args="-o StrictHostKeyChecking=no" ./galaxy/test.yml
  EOT
}
}
