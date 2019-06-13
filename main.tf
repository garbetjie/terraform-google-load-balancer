data google_project project {

}

resource google_compute_global_address lb {
  count = var.reserve_address ? 1 : 0
  name = format("%s-load-balancer", var.name)
}

# TODO implement HTTPS forwarding rule.

resource google_compute_global_forwarding_rule http {
  name = format("%s-http", var.name)
  target = google_compute_target_http_proxy.lb.self_link
  ip_address = local.address
  port_range = 80
}

resource google_compute_backend_service lb {
  count = length(local.backend_services)
  name = local.backend_services[count.index].name
  health_checks = var.health_checks

  dynamic "backend" {
    for_each = local.backend_services[count.index].targets

    content {
      group = backend.value
    }
  }

  provisioner "local-exec" {
    command = format("%s/remove-backend.sh", path.module)
    when = "destroy"
    on_failure = "continue"
    environment = {
      PATH_MATCHER_NAME = self.name
      URL_MAP_NAME = var.name
      PROJECT_ID = data.google_project.project.project_id
      DUMMY_SERVICE_LINK = google_compute_backend_service.dummy.self_link
    }
  }
}

resource google_compute_backend_bucket buckets {
  count = length(local.backend_buckets)
  name = local.backend_buckets[count.index].name
  bucket_name = local.backend_buckets[count.index].target

  provisioner "local-exec" {
    command = format("%s/remove-backend.sh", path.module)
    when = "destroy"
    on_failure = "continue"
    environment = {
      PATH_MATCHER_NAME = self.name
      URL_MAP_NAME = var.name
      PROJECT_ID = data.google_project.project.project_id
      DUMMY_SERVICE_LINK = google_compute_backend_service.dummy.self_link
    }
  }
}

resource google_compute_backend_service dummy {
  name = format("%s-dummy", var.name)
  health_checks = var.health_checks
}

resource google_compute_target_http_proxy lb {
  name = format("%s-http", var.name)
  url_map = google_compute_url_map.default.self_link
}

//# TODO Implement HTTPS proxies.
//resource google_compute_target_https_proxy "" {
//  name = ""
//  ssl_certificates = []
//  url_map = ""
//}

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
