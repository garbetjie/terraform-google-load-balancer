resource google_compute_global_address lb {
  name = format("%s-load-balancer", var.name)
}
