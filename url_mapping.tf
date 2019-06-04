resource google_compute_url_map default {
  name = var.name
  default_service = local.default_backend_service

  dynamic "host_rule" {
    for_each = local.backend_service_index

    content {
      path_matcher = host_rule.key
      hosts = flatten([
        for item in concat(local.backend_services, local.backend_buckets):
          item.hosts
        if item.name == host_rule.key
      ])
    }
  }

  dynamic "path_matcher" {
    for_each = local.backend_service_index

    content {
      name = path_matcher.key
      default_service = path_matcher.value
    }
  }
}
