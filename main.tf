# TODO implement HTTPS forwarding rule.

data google_project project {

}

resource google_compute_global_forwarding_rule http {
  name = format("%s-http", var.name)
  target = google_compute_target_http_proxy.http_proxy.self_link
  ip_address = var.address
  port_range = "80-80"
}

resource google_compute_target_http_proxy http_proxy {
  name = format("%s-http", var.name)
  url_map = google_compute_url_map.url_map.self_link
}

resource google_compute_url_map url_map {
  name = var.name
  default_service = local.default_service_link

  dynamic "path_matcher" {
    for_each = local.path_matchers

    content {
      default_service = path_matcher.value.default_service
      name = path_matcher.value.name
    }
  }

  dynamic "host_rule" {
    for_each = local.host_rules

    content {
      hosts = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }
}

resource google_compute_backend_service backend_service {
  count = length(local.backend_services)
  name = local.backend_services[count.index].name
  health_checks = var.health_checks

  dynamic "backend" {
    for_each = local.backend_services[count.index].groups

    content {
      group = backend.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource google_compute_backend_bucket backend_bucket {
  count = length(local.backend_buckets)
  name = local.backend_buckets[count.index].name
  bucket_name = local.backend_buckets[count.index].bucket

  lifecycle {
    create_before_destroy = true
  }
}
