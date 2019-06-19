variable "name" {
  type = string
}

variable "health_checks" {
  type = list
}

variable "default_backend" {
  type = list
}

variable "address" {
  type = string
  description = "IP address to assign to the load balancer."
}
variable "services" {
  type = list
  default = []
}

variable "buckets" {
  type = list
  default = []
}


locals {
  default_service_link = concat(
    [
      for index, item in local.backend_services:
        format("https://www.googleapis.com/compute/v1/projects/%s/global/backendServices/%s", data.google_project.project.project_id, item.name)
      if lower(var.default_backend[0]) == "service" && tostring(var.default_backend[1]) == tostring(index)
    ],
    [
      for index, item in local.backend_buckets:
        format("https://www.googleapis.com/compute/v1/projects/%s/global/backendBuckets/%s", data.google_project.project.project_id, item.name)
      if lower(var.default_backend[0]) == "bucket" && tostring(var.default_backend[1]) == tostring(index)
    ]
  )[0]

  backend_services = [
    for index, item in var.services: {
      name = format("%s-service-%02d", var.name, index + 1)
      hosts = item.hosts
      host_hash = sha256(jsonencode(sort(item.hosts)))
      groups = item.groups
    }
  ]

  backend_buckets = [
    for index, item in var.buckets: {
      name = format("%s-bucket-%02d", var.name, index + 1)
      hosts = item.hosts
      host_hash = sha256(jsonencode(sort(item.hosts)))
      bucket = item.bucket
    }
  ]

  path_matchers = concat(
    [
      for index, item in local.backend_buckets: {
        name = item.name
        default_service = google_compute_backend_bucket.backend_bucket[index].self_link
      }
      if length(item.hosts) > 0
    ],
    [
      for index, item in local.backend_services: {
        name = item.name
        default_service = google_compute_backend_service.backend_service[index].self_link
      }
      if length(item.hosts) > 0
    ]
  )

  host_rules = concat(
    [
      for index, item in local.backend_buckets: {
        path_matcher = item.name
        hosts = item.hosts
      }
      if length(item.hosts) > 0
    ],
    [
      for index, item in local.backend_services: {
        path_matcher = item.name
        hosts = item.hosts
      }
      if length(item.hosts) > 0
    ]
  )
}
