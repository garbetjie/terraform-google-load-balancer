variable "name" {
  type = string
  description = "Name of the load balancer (as displayed in the Google Cloud Console)."
}

variable "default_backend" {
  type = tuple([string, number])
  description = "Backend type and index to select as the default backend. Must be a tuple with the first index being one of `bucket` or `service`, and the second the index of the bucket or service designated as the default."
}

variable "address" {
  type = string
  description = "IP address to assign to the load balancer."
}
variable "services" {
  type = list
  default = []
  description = "List of objects used to define the backend services for the load balancer."
}

variable "buckets" {
  type = list
  default = []
  description = "List of objects used to define the backend buckets for the load balancer."
}


locals {
  default_service_link = length(local.default_service_links) > 0 ? local.default_service_links[0] : ""

  default_service_links = concat(
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
  )

  backend_services = [
    for index, item in var.services: {
      name = format("%s-service-%02d", var.name, index + 1)
      hosts = lookup(item, "hosts", [])
      groups = item.groups
      health_check = item.health_check
    }
  ]

  backend_buckets = [
    for index, item in var.buckets: {
      name = format("%s-bucket-%02d", var.name, index + 1)
      hosts = lookup(item, "hosts", [])
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
