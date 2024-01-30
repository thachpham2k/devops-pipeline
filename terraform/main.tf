# data
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source             = "./modules/vpc"
  region             = local.region
  module_tags        = var.tags
  module_name        = var.project
  vpc_cidr           = var.vpc_cidr
  number_of_az       = 3
  has_public_subnet  = true
  has_private_subnet = true
  nat_az             = 1
  has_nat_gateway    = false
}

module "keypair" {
  source   = "./modules/keypair"
  key_name = "${var.project}-keypair"
  key_path = var.key_path
  key_tags = var.tags
}
# wsl gặp lỗi với cấu hình quyền của file của host nên phải mang key sang wsl để sử dụng
resource "null_resource" "change-keypair-directory" {
  provisioner "local-exec" {
    command = <<EOT
    cp ${var.key_path}/${var.project}-keypair.pem ~/${var.project}-keypair.pem && \
    chmod 400 ~/${var.project}-keypair.pem
  EOT
  }

  depends_on = [module.keypair]
}

resource "null_resource" "delete-keypair" {

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "rm -f ~/${var.project}-keypair.pem"
  }
}
# ========================================
# Gitlab
# ========================================
resource "aws_security_group" "sgr-gitlab" {
  name        = "${var.project}-sgr-gitlab"
  description = "allow ssh connection from all resource"
  vpc_id      = module.vpc.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = merge({ "Name" = "${var.project}-sgr-gitlab" }, var.tags)
}

resource "aws_instance" "i-gitlab" {
  instance_type               = "t3.medium"
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = element(keys(module.vpc.publicsubnet), 0)
  security_groups             = [aws_security_group.sgr-gitlab.id]
  key_name                    = module.keypair.keypair-name
  associate_public_ip_address = true
  disable_api_termination     = false
  ebs_optimized               = false
  tags                        = merge({ "Name" = "${var.project}-gitlab" }, var.tags)

  provisioner "local-exec" {
    command = "echo '[gitlab]\n${self.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=~/${var.project}-keypair.pem' > gitlab/inventory.ini"
  }

  depends_on = [aws_security_group.sgr-gitlab, module.vpc, module.keypair]
}

resource "null_resource" "ansible-gitlab-run" {
  provisioner "local-exec" {
    command = <<EOT
    aws ec2 wait instance-running \
      --instance-ids ${aws_instance.i-gitlab.id} \
      --region ${local.region} && \
    sleep 20 && \
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      -e GITLAB_IP=${aws_instance.i-gitlab.public_ip} \
      -i gitlab/inventory.ini gitlab/playbook.yml
  EOT
  }
  depends_on = [aws_instance.i-gitlab, null_resource.change-keypair-directory]
}

resource "null_resource" "ansible-gitlab-getpass" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/${var.project}-keypair.pem")
    host        = aws_instance.i-gitlab.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cat /deploy/gitlab_password.txt",
    ]
  }
  depends_on = [null_resource.ansible-gitlab-run]
}

# ========================================
# Gitlab-runner
# ========================================
resource "aws_security_group" "sgr-gitlab-runner" {
  name        = "${var.project}-sgr-gitlab-runner"
  description = "security group for gitlab-runner instance"
  vpc_id      = module.vpc.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 5040
    to_port     = 5040
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = merge({ "Name" = "${var.project}-sgr-gitlab-runner" }, var.tags)
}

# resource "aws_instance" "i-gitlab-runner" {
#   instance_type               = "t3.medium"
#   ami                         = data.aws_ami.ubuntu.id
#   subnet_id                   = element(keys(module.vpc.publicsubnet), 0)
#   security_groups             = [aws_security_group.sgr-gitlab-runner.id]
#   key_name                    = module.keypair.keypair-name
#   associate_public_ip_address = true
#   disable_api_termination     = false
#   ebs_optimized               = false
#   tags                        = merge({ "Name" = "${var.project}-gitlab-runner" }, var.tags)

#   depends_on = [aws_security_group.sgr-gitlab-runner, module.vpc, module.keypair]
# }

# ========================================
# Deployment
# ========================================
resource "aws_security_group" "sgr-deploy-instance" {
  name        = "${var.project}-sgr-deploy-instance"
  description = "allow all connection from all resource"
  vpc_id      = module.vpc.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = merge({ "Name" = "${var.project}-sgr-deploy-instance" }, var.tags)
}
