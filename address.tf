resource google_compute_global_address address {
  name = format("%s-lb", var.name)
}
