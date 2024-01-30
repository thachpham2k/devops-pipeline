variable "region" {
  default = "ap-southeast-1"
}

variable "module_tags" {
  description = "Project tags"
  type        = map(any)
  default = {
    "Project" : "vpc"
    "author" : "terraform"
  }
}

variable "module_name" {
  description = "Prefix of vpc name. EG: input: 'test' -> vpc's name is 'test-vpc'"
  default     = "vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 32))
    error_message = "Must be valid IPv4 CIDR."
  }

  validation {
    condition = can(regex("^(10\\.\\d{1,3}\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.)\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.vpc_cidr))
    # condition = anytrue(
    #   [
    #     can(regex("^(10\\.\\d{1,3}\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.)\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.vpc_cidr))
    #   ]
    # )
    error_message = "Must be a valid IPv4 CIDR block address."
  }
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

variable "has_public_subnet" {
  description = "Do you want to have public subnet?"
  type        = bool
  default     = false
}

variable "has_private_subnet" {
  description = "Do you want to have private subnet?"
  type        = bool
  default     = false
}

variable "nat_az" {
  description = "Select az locate nat? (Choose 0 is not have nat)"
  type        = number
  default     = 0

  validation {
    condition     = (var.nat_az >= 0 && var.nat_az <= 3)
    error_message = "(NAT AZ = 0 -> not have nat) or (NAT AZ > 0 and <= number of public subnet) (Note: You need to have public subnet in order to locate nat)"
  }
}

variable "has_nat_gateway" {
  description = "True to choose nat gateway and false to choose nat instance"
  type        = bool
  default     = false
}