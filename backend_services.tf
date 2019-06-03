resource google_compute_region_backend_service default {
  count = length(var.mapping)
  name = format("%s-%0s", var.name, var.mapping[count.index]["name"])
  health_checks = var.health_checks

  dynamic "backend" {
    for_each = var.mapping[count.index]["instance_groups"]

    content {
      group = backend.value
    }
  }
}
