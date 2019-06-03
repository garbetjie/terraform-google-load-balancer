resource google_compute_backend_service default {
  count = length(var.mapping)
  name = format("%s-%s", var.name, var.mapping[count.index]["name"])
  health_checks = var.health_checks

  dynamic "backend" {
    for_each = var.mapping[count.index]["targets"]

    content {
      group = backend.value
    }
  }
}
