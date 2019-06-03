resource google_compute_global_forwarding_rule http {
  name = format("%s-http", var.name)
  target = google_compute_target_http_proxy.lb.self_link
  ip_address = google_compute_global_address.lb.address
  port_range = 80
}

# TODO implement HTTPS forwarding rule.
