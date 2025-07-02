variable "env" {
  type = string
}
variable "project" {
  type = string
}
variable "cpu" {
  type = number
}
variable "memory" {
  type = number
}
variable "desired_count" {
  type = number
}
variable "log_level" {
  type = string
}
variable "greeting_message" {
  type = string
}
variable "image_tag" {
  type = string
  default = "bootstrap" # makes the image tag optional
}
variable "log_group_prefix" {
  description = "Shared prefix for all log groups"
  type        = string
  default     = "emilian-applogs"
}