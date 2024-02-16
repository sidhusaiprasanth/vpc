locals {
  reqd_azs         = slice(keys({ for az, details in data.aws_ec2_instance_type_offerings.this_ec2_ins_offrs : az => details.instance_types if length(details.instance_types) != 0 }), 0, 2)
  reqd_pub_cidrs   = slice(var.pub_subnets, 0, 2)
  reqd_pri_cidrs   = slice(var.pri_subnets, 0, 2)
  reqd_pub_sub_map = tomap(zipmap(local.reqd_azs, local.reqd_pub_cidrs))
  reqd_pri_sub_map = tomap(zipmap(local.reqd_azs, local.reqd_pri_cidrs))

  eks_cluster_name = "${var.cluster_name}-${var.env}"

  k8s_pub_tags = {
    "kubernetes.io/role/elb"                          = 1
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
  }

  k8s_pri_tags = {
    "kubernetes.io/role/internal-elb"                 = 1
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
  }


}



resource "aws_vpc" "thisvpc" {
  cidr_block         = var.cidr_block
  instance_tenancy   = "default"
  enable_dns_support = true

  tags = merge({
    "Type" = "Main-VPC",
    "Name" = "${var.cluster_name}-${var.env}-VPC"
  }, var.default_tags)
}

resource "aws_internet_gateway" "this_igw" {
  depends_on = [aws_vpc.thisvpc]
  vpc_id = aws_vpc.thisvpc.id
  tags = merge({
    "Name" = "${var.cluster_name}-${var.env}-IGW"
  }, var.default_tags)
}

resource "aws_subnet" "this_pub_sub" {
  depends_on = [aws_vpc.thisvpc]
  for_each                = local.reqd_pub_sub_map
  vpc_id                  = aws_vpc.thisvpc.id
  map_public_ip_on_launch = true
  availability_zone       = each.key
  cidr_block              = each.value

  tags = merge({
    "Kind" = "Public-Subnet",
    "Name" = "${var.cluster_name}-${var.env}-PUB-SUB-${each.key}"
  }, var.default_tags, local.k8s_pub_tags)
}

resource "aws_subnet" "this_pri_sub" {
  depends_on = [aws_vpc.thisvpc]
  for_each          = local.reqd_pri_sub_map
  vpc_id            = aws_vpc.thisvpc.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = merge({
    "Kind" = "Private-Subnet",
    "Name" = "${var.cluster_name}-${var.env}-PRI-SUB-${each.key}"
  }, var.default_tags, local.k8s_pri_tags)
}


# NatGW

resource "aws_eip" "this_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this_igw]

}

resource "aws_nat_gateway" "this_ngw" {
  depends_on    = [aws_subnet.this_pub_sub, aws_subnet.this_pri_sub, aws_internet_gateway.this_igw]
  allocation_id = aws_eip.this_eip.id
  subnet_id     = element([for subnet in aws_subnet.this_pub_sub: subnet.id], 0)
  tags = merge({
    "Type" = "NGW",
    "Name" = "${var.cluster_name}-${var.env}-NAT-GW"
  }, var.default_tags)
}

## Route table

resource "aws_route_table" "this_pub_rtb" {
  depends_on = [aws_internet_gateway.this_igw, aws_nat_gateway.this_ngw]
  vpc_id = aws_vpc.thisvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this_igw.id
  }

  tags = merge({
    "Type" = "PUB_RTB",
    "Name" = "${var.cluster_name}-${var.env}-PUB-RT"
  }, var.default_tags)
}


resource "aws_route_table" "this_pri_rtb" {
  depends_on = [aws_internet_gateway.this_igw, aws_nat_gateway.this_ngw]
  vpc_id = aws_vpc.thisvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this_ngw.id
  }

  tags = merge({
    "Type" = "PRI_RTB",
    "Name" = "${var.cluster_name}-${var.env}-PRI-RT"
  }, var.default_tags)
}


resource "aws_route_table_association" "this_pub_rt-asso" {
  depends_on = [aws_route_table.this_pub_rtb, aws_route_table.this_pri_rtb]
  for_each = aws_subnet.this_pub_sub
  subnet_id = each.value.id

  route_table_id = aws_route_table.this_pub_rtb.id
}

resource "aws_route_table_association" "this_pri_rt-asso" {
  depends_on = [aws_route_table.this_pub_rtb, aws_route_table.this_pri_rtb]
  for_each = aws_subnet.this_pri_sub
  subnet_id =  each.value.id
  route_table_id = aws_route_table.this_pri_rtb.id
}










