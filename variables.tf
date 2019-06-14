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

variable "address" {
  type = string
  description = "IP address to assign to the load balancer."
}

variable "reserve_address" {
  type = bool
  default = true
}

locals {
  default_service_name = [
    for item in concat(local.backend_services, local.backend_buckets):
      item.name
    if item.index == var.default_route
  ][0]

  default_service_link = [
    for item in concat(google_compute_backend_bucket.backend_bucket.*, google_compute_backend_service.backend_service.*):
      item.self_link
    if item.name == local.default_service_name
  ][0]

  service_to_hosts_map = {
    for index, item in var.routing:
      format("%s-%s", var.name, substr(sha256(jsonencode(sort(item.hosts))), 0, 8)) => item.hosts
  }

  host_hash_to_hosts_map = {
    for index, item in var.routing:
      sha256(jsonencode(sort(item.hosts))) => item.hosts
  }

  backend_services = [
    for index, item in var.routing: {
      name = format("%s-%s", var.name, substr(sha256(jsonencode(sort(item.hosts))), 0, 8))
      targets = item.targets
      host_hash = sha256(jsonencode(sort(item.hosts)))
      index = index
    }
    if substr(item.targets[0], 0, 34) == "https://www.googleapis.com/compute"
  ]

  backend_buckets = [
    for index, item in var.routing: {
      name = format("%s-%s", var.name, substr(sha256(jsonencode(sort(item.hosts))), 0, 8))
      target = item.targets[0]
      host_hash = sha256(jsonencode(sort(item.hosts)))
      index = index
    }
    if substr(item.targets[0], 0, 34) != "https://www.googleapis.com/compute"
  ]

  path_matchers = concat(
    [
      for index, item in local.backend_buckets: {
        default_service = google_compute_backend_bucket.backend_bucket[index].self_link
        name = item.name
      }
    ],
    [
      for index, item in local.backend_services: {
        default_service = google_compute_backend_service.backend_service[index].self_link
        name = item.name
      }
    ]
  )

  host_rules = concat(
    [
      for index, item in local.backend_buckets: {
        hosts = local.host_hash_to_hosts_map[item.host_hash]
        path_matcher = item.name
      }
    ],
    [
      for index, item in local.backend_services: {
        hosts = local.host_hash_to_hosts_map[item.host_hash]
        path_matcher = item.name
      }
    ]
  )
}
