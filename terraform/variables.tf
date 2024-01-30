locals {
  region = "ap-southeast-1"
}

variable "tags" {
  description = "Project tags"
  type        = map(any)
  default = {
    "Project" : "vpc"
    "author" : "terraform"
  }
}

variable "project" {
  description = "project name. EG: input: 'test' -> vpc's name is 'test-vpc'"
  default     = "devops-pipeline"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  # default     = "10.1.0.0/16"
}

variable "number_of_az" {
  description = "Choose the number of AZs in which to provision subnets. We recommend at least two AZs for high availability"
  type        = number
  default     = 1
  validation {
    condition     = var.number_of_az >= 0 && var.number_of_az <= 3
    error_message = "Number of AZ does not smaller than 0 and bigger than 3"
  }
}

variable "key_path" {
  description = "Where keypair file saved"
  default     = "."
}