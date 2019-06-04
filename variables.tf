variable "name" {
  type = string
}

variable "routing" {
  type = list
}

variable "health_checks" {
  type = list
}

variable "default_route" {
  type = number
}

locals {
  backend_services = [
    for index, item in var.routing: {
      name = format("%s-%s", var.name, index)
      targets = item.targets
      index = index
      hosts = item.hosts
    }
    if substr(item.targets[0], 0, 34) == "https://www.googleapis.com/compute"
  ]

  backend_buckets = [
    for index, item in var.routing: {
      name = format("%s-%s", var.name, index)
      index = index
      target = item.targets[0]
      hosts = item.hosts
    }
    if substr(item.targets[0], 0, 34) != "https://www.googleapis.com/compute"
  ]

  backend_service_index = merge(
    {
      for index, item in local.backend_services:
        item.name => google_compute_backend_service.lb[index].self_link
    },
    {
      for index, item in local.backend_buckets:
        item.name => google_compute_backend_bucket.buckets[index].self_link
    }
  )

  default_backend_service = [
    for item in concat(local.backend_services, local.backend_buckets):
      local.backend_service_index[item.name]
    if item.index == var.default_route
  ][0]
}
