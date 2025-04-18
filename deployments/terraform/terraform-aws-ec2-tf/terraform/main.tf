# Terraform provision AWS EC2 instance with Terraform Cloud Management
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # Use the correct CIDR for your VPC
}
variable "awsprops" {
  type = map(any)
  default = {
    region       = "us-east-1"
    vpc          = "vpc-0649b09d7dc0a92c3"
    ami          = "ami-084568db4383264d4"
    itype        = "t2.micro"
    subnet       = "subnet-0ef56be70575e12cc"
    publicip     = true
    keyname      = "terraform-demo-lanche"
    secgroupname = "prodxcloud-aws-ec2-lab-1"
  }
}


// AMI Security group setting using HashiCorp Configuration Language (HCL)
resource "aws_security_group" "prod-sec-sg" {
  name        = var.instance_secgroupname
  description = var.instance_secgroupname
  vpc_id      = var.instance_vpc_id

  // To Allow SSH Transport

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = lookup(ingress.value, "description", null)
      from_port   = lookup(ingress.value, "from_port", null)
      to_port     = lookup(ingress.value, "to_port", null)
      protocol    = lookup(ingress.value, "protocol", null)
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "allow_tls"
  }

  lifecycle {
    create_before_destroy = false
  }
}


# instance identity
resource "aws_instance" "project-iac-2" {
  ami                         = lookup(var.awsprops, "ami")
  instance_type               = lookup(var.awsprops, "itype")
  subnet_id                   = lookup(var.awsprops, "subnet")
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name                    = "terraform-demo-lanche"


  vpc_security_group_ids = [
    aws_security_group.prod-sec-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    volume_size           = 40
    volume_type           = "gp2"
  }
  tags = {
    Name        = "prodxcloud-aws-ec2-lab-1"
    Environment = "DEV"
    OS          = "UBUNTU"
    Managed     = "PRODXCLOUD"
  }

  provisioner "file" {
    source      = "installer.sh"
    destination = "/tmp/installer.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/installer.sh",
      "sh /tmp/installer.sh"
    ]

  }
  depends_on = [aws_security_group.prod-sec-sg]


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("./terraform-demo-lanche.pem")
  }
}


output "ec2instance" {
  value = aws_instance.project-iac-2.public_ip
}

