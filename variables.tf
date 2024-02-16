variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "env" {
  type    = string
  default = "dev1"
}

variable "cluster_name" {
  type    = string
  default = "sid-k8s-cluster"
}

variable "default_tags" {
  type = map(string)
  default = {
    "Tier"       = "frontend",
    "Department" = "Finance"
  }
}

variable "pub_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "pri_subnets" {
  type    = list(string)
  default = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
}




