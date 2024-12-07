variable "aws_region" {
  description = "The AWS region to deploy primary resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region name, e.g., us-east-1"
  }
}

variable "dr_region" {
  description = "The AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.dr_region))
    error_message = "DR region must be a valid region name, e.g., us-west-2"
  }
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'"
  }
}

variable "chain_name" {
  description = "Name of the blockchain"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.chain_name))
    error_message = "Chain name must start with a letter and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "instance_types" {
  description = "Map of instance types for different node roles"
  type = object({
    validator = string
    seed      = string
    explorer  = string
  })
  default = {
    validator = "t3.medium"
    seed      = "t3.small"
    explorer  = "t3.medium"
  }

  validation {
    condition     = can([for type in values(var.instance_types) : regex("^[a-z][0-9][.][a-z]+$", type)])
    error_message = "Instance types must be valid AWS instance type names"
  }
}

variable "enable_monitoring" {
  description = "Enable enhanced monitoring and alerting"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days"
  }
}
