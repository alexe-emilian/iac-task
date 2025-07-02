variable "project" {
  description = "Project identifier (iac-task)"
  type = string
}
variable "env" {
  description = "Environment (dev | prod)"
  type = string
}
variable "tags" {
  description = "Merged default + env tags"
  type = map(string)
}
