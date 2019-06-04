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
}

resource google_compute_backend_bucket buckets {
  count = length(local.backend_buckets)
  name = local.backend_buckets[count.index].name
  bucket_name = local.backend_buckets[count.index].target
}
