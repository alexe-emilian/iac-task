variable "project" {
  type = string
}
variable "env" {
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
variable "image_uri" {
  type = string
}
variable "image_tag" {
  type = string
}
variable "log_level" {
  type = string
}
variable "greeting_message" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "target_group_arn" {
  type = string
}
variable "alb_sg_id" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "log_group_prefix" {
  type = string
}
variable "log_retention" {
  type    = number
  default = 7
}