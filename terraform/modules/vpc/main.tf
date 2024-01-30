data "aws_availability_zones" "availability_zone" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

locals {
  validated_nat_az = (var.nat_az > 0 && var.nat_az <= var.number_of_az) ? (var.has_public_subnet == true ? var.number_of_az : 0) : 0
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags       = merge({ Name = "${var.module_name}-vpc" }, var.module_tags)
}

# Subnet
resource "aws_subnet" "privatesubnet" {
  count = var.has_private_subnet ? var.number_of_az : 0

  availability_zone = tolist(data.aws_availability_zones.availability_zone.names)[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 1)

  depends_on = [
    aws_vpc.vpc
  ]

  tags = merge({ Name = "${var.module_name}-privatesubnet-${count.index + 1}-${tolist(data.aws_availability_zones.availability_zone.names)[count.index]}" }, var.module_tags)
}

resource "aws_subnet" "publicsubnet" {
  count = var.has_public_subnet ? var.number_of_az : 0

  availability_zone = tolist(data.aws_availability_zones.availability_zone.names)[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 100)

  depends_on = [
    aws_vpc.vpc
  ]

  tags = merge({ Name = "${var.module_name}-publicsubnet-${count.index + 1}-${tolist(data.aws_availability_zones.availability_zone.names)[count.index]}" }, var.module_tags)
}

# Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({ Name = "${var.module_name}-igw" }, var.module_tags)
}

# NAT Gateway
resource "aws_eip" "eip" {
  count  = (local.validated_nat_az > 0 && var.has_nat_gateway == true) ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "natgateway" {
  count = (local.validated_nat_az > 0 && var.has_nat_gateway == true) ? 1 : 0

  allocation_id = aws_eip.eip[0].id
  subnet_id     = aws_subnet.publicsubnet[local.validated_nat_az - 1].id

  tags = merge({ Name = "${var.module_name}-natgateway" }, var.module_tags)
}

# NAT instance
data "aws_ami" "ami-natinstance" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}

resource "aws_instance" "natinstance" {
  count = (local.validated_nat_az > 0 && var.has_nat_gateway == false) ? 1 : 0

  instance_type               = "t2.micro"
  ami                         = data.aws_ami.ami-natinstance.id
  subnet_id                   = aws_subnet.publicsubnet[local.validated_nat_az - 1].id
  security_groups             = [aws_security_group.sgr-natinstance.id]
  source_dest_check           = false
  associate_public_ip_address = true

  tags = merge({ Name = "${var.module_name}-nat-instance" }, var.module_tags)
}

resource "aws_security_group" "sgr-natinstance" {
  name        = "${var.module_name}-sgr-natinstance"
  description = "allow all traffic from private subnet"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    # for_each = { for k, v in var.private-subnet : k => v }
    for_each = aws_subnet.privatesubnet
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["${ingress.value.cidr_block}"]
    }
  }
  # ingress {
  #     cidr_blocks = [aws_subnet.privatesubnet.cidr_block]
  #     from_port = 0
  #     to_port = 0
  #     protocol = "-1" 
  # }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = merge({ Name = "${var.module_name}-sgr-natinstance" }, var.module_tags)
}

# Route Table
# RouteTable for private subnet
resource "aws_route_table" "prisub_routetable" {
  count = length(aws_subnet.privatesubnet)

  vpc_id = aws_vpc.vpc.id

  dynamic "route" {
    for_each = aws_nat_gateway.natgateway

    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = route.value.id
    }
  }

  dynamic "route" {
    for_each = aws_instance.natinstance

    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = route.value.primary_network_interface_id
    }
  }

  tags = merge({ Name = "${var.module_name}-routetable-for-prisubnet-${count.index + 1}" }, var.module_tags)
}

resource "aws_route_table_association" "prisub_routetable_association" {
  count = length(aws_subnet.privatesubnet)

  subnet_id      = aws_subnet.privatesubnet[count.index].id
  route_table_id = aws_route_table.prisub_routetable[count.index].id
}
# RouteTable for public subnet
resource "aws_route_table" "pubsub_routetable" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge({ Name = "${var.module_name}-routetable-for-pubsubnet" }, var.module_tags)
}

resource "aws_route_table_association" "route-table-association-publicsubnet" {
  count = length(aws_subnet.publicsubnet)

  subnet_id      = aws_subnet.publicsubnet[count.index].id
  route_table_id = aws_route_table.pubsub_routetable.id
}