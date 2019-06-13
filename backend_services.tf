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
