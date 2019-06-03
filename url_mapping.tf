resource google_compute_url_map default {
  name = var.name
  default_service = local.default_backend_service[0]

  dynamic "host_rule" {
    for_each = var.mapping

    content {
      path_matcher = host_rule.value.name
      hosts = host_rule.value.hosts
    }
  }

  dynamic "path_matcher" {
    for_each = var.mapping

    content {
      name = path_matcher.value.name
      default_service = google_compute_backend_service.lb[path_matcher.key].self_link
    }
  }
}

locals {
  default_backend_service = [
    for mp in google_compute_backend_service.lb:
      mp.self_link
    if mp.name == format("%s-%s", var.name, var.default_mapping)
  ]
}
