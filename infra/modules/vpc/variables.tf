variable "project" {
  description = "Project identifier (iac-task)"
  type        = string
}

variable "env" {
  description = "Environment (dev | prod)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many AZs to span (max 3 in eu-central-1 for free tier)"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
}
