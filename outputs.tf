output "vpc_id" {
  value = aws_vpc.thisvpc.id
}

output "vpc_arn" {
  value = aws_vpc.thisvpc.arn
}

output "vpc_owner_id" {
  value = aws_vpc.thisvpc.owner_id
}

output "azs_supported_t3_medium" {
  value = keys({ for az, details in data.aws_ec2_instance_type_offerings.this_ec2_ins_offrs : az => details.instance_types if length(details.instance_types) != 0 })
}

output "pub_subnets_ids_list" {
  value = [for subnet in aws_subnet.this_pub_sub : subnet.id]
}

output "pri_subnets_ids_list" {
  value = [for subnet in aws_subnet.this_pri_sub : subnet.id]
}

output "pub_subnets_ids" {
  value = { for az, subnet in aws_subnet.this_pub_sub : az => subnet.id }
}

output "pri_subnets_ids" {
  value = { for az, subnet in aws_subnet.this_pri_sub : az => subnet.id }
}

output "values_pub_sub_ids" {
  value = values({ for az, subnet in aws_subnet.this_pub_sub : az => subnet.id })
}

output "values_pri_sub_ids" {
  value = values({ for az, subnet in aws_subnet.this_pri_sub : az => subnet.id })
}
