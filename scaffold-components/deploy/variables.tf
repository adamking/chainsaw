variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
}
variable "env" {
  description = "The env - either 'testnet' or 'mainnet' -- used as suffix of resource names"
  type        = string
}

variable "project" {
  description = "The name of this project -- used as prefix of resource names"
  default     = "newchain"
  type        = string
}

variable "ssh_private_key_path" {
  description = "path to private SSH key file"
  default     = "~/.ssh/id_rsa.old"
  type        = string
}

variable "ssh_public_key_path" {
  description = "path to public SSH key file"
  default     = "~/.ssh/id_rsa.old.pub"
  type        = string
}

variable "tls_certificate_email" {
  description = "email to send to letsencrypt for tls certificates"
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
  default     = "10.0.0.0/16"
}

variable "seed_subnet_cidr" {
  description = "CIDR block for seed subnet"
  default     = "10.0.1.0/24"
}

variable "validator_subnet_cidr" {
  description = "CIDR block for validator subnet"
  default     = "10.0.2.0/24"
}

variable "explorer_subnet_cidr" {
  description = "CIDR block for explorer subnet"
  default     = "10.0.3.0/24"
}

variable "num_validator_instances" {
  description = "number of validator instances"
  type        = number
  default     = 0
}

variable "num_seed_instances" {
  description = "number of seed instances"
  type        = number
  default     = 0
}

variable "create_explorer" {
  description = "whether to include an explorere node"
  type        = bool
  default     = false
}

variable "dns_zone_parent" {
  description = "parent of dns zone for testnet and mainnet servers, eg: mychain.example.com"
}

variable "validator_keys_passphrase" {
  description = "passphrase for validator keys"
}

variable "console_password" {
  description = "password for the user 'ubuntu'"
}

variable "token_name" {
  description = "name of the blockhain's token, eg MYTOKEN"
}
