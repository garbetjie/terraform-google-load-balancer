variable "name" {
  type = "string"
}

variable "mapping" {
  type = "list"
}

variable "health_checks" {
  type = list
}

variable "default_mapping" {
  type = "string"
}
