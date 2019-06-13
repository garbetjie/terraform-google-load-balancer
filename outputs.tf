output "address" {
  value = var.reserve_address ? google_compute_global_address.lb[0].address : null
  description = "IP address of the load balancer (if managed by this module)."
}

output "address_link" {
  value = var.reserve_address ? google_compute_global_address.lb[0].self_link : null
  description = "Full URL of the load balancer's address (if managed by this module)."
}
