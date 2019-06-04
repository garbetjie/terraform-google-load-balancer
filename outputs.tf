output "address" {
  value = google_compute_global_address.lb.address
}

output "address_link" {
  value = google_compute_global_address.lb.self_link
}
