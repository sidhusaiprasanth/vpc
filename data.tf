data "aws_availability_zones" "this_azs" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ec2_instance_type_offerings" "this_ec2_ins_offrs" {
  for_each = toset(data.aws_availability_zones.this_azs.names)
  filter {
    name   = "instance-type"
    values = ["t3.medium"]
  }

  filter {
    name   = "location"
    values = ["${each.key}"]
  }

  location_type = "availability-zone"
}


