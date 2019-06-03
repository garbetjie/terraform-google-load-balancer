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
