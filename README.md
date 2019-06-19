# Load Balancer Terraform Module (Google)

Wrapper around the complexity of configuring a global load balancer on Google's Cloud Platform. It manages all the resources
required to direct traffic to the provided sets of buckets or instance groups.


## Usage

> **Please note:** Due to the way the dependency graph is currently being evaluated in Terraform, the removal of buckets
> or services from the load balancer must be done in two steps. Please see [Removing a service or bucket](#removing-a-service-or-bucket)
> for more information on how to do this.
>
> Additionally, removing a load balancer is a two-step process too (and _will_ generate an error). This is shown in
> [Removing a load balancer](#removing-a-load-balancer).


### Creating a load balancer 

```hcl
resource google_compute_global_address my_address {
  name = "load-balancer"
}

resource google_compute_instance_group my_group {
  name = "my-group"
  zone = "europe-west4-a"
}

resource google_storage_bucket my_bucket1 {
  name = "my-bucket1"
}

resource google_storage_bucket my_bucket2 {
  name = "my-bucket2"
}

resource google_compute_health_check my_healthcheck {
  name = "my-health-check"
  
  http_health_check {
    
  }
}

module load_balancer {
  source = "garbetjie/load-balancer/google"
  
  name = "load-balancer" 
  default_backend = ["service", 0]  // or ["bucket", 1] for the bucket defined for "2.static.example.org".
  health_checks = [google_compute_health_check.my_healthcheck]
  address = google_compute_global_address.my_address.address
  
  buckets = [
    { hosts = ["1.static.example.org"], bucket = google_storage_bucket.my_bucket1.name },
    { hosts = ["2.static.example.org"], bucket = google_storage_bucket.my_bucket2.name },
    { hosts = ["3.static.example.org"], bucket = google_storage_bucket.my_bucket1.name },
  ]
  
  services = [
    { hosts = ["api.example.org", "example.org"], groups = [google_compute_instance_group.my_group.self_link] },
    { hosts = ["2.api.example.org", "2.example.org"], groups = [google_compute_instance_group.my_group.self_link] },
    { hosts = ["3.api.example.org", "3.example.org"], groups = [google_compute_instance_group.my_group.self_link] },
  ]
}
```


### Removing a service or bucket

Firstly, the buckets or services to be removed need to be moved to the end of their configuration, and the hosts to which
they're assigned need to be emptied.

Using the same example as in creating a load balancer (shown above), it would become (notice how the `2.static.example.org`
and `["2.api.example.org", "2.example.org"]` hosts have been moved to the end, and emptied):

#### Step 1: Empty the `hosts` properties.

```hcl
module load_balancer {
  source = "garbetjie/load-balancer/google"
  
  name = "load-balancer" 
  default_backend = ["service", 0]
  health_checks = [google_compute_health_check.my_healthcheck]
  address = google_compute_global_address.my_address.address
  
  buckets = [
    { hosts = ["1.static.example.org"], bucket = google_storage_bucket.my_bucket1.name },
    { hosts = ["3.static.example.org"], bucket = google_storage_bucket.my_bucket1.name },
    { hosts = [], bucket = google_storage_bucket.my_bucket2.name },
  ]
  
  services = [
    { hosts = ["api.example.org", "example.org"], groups = [google_compute_instance_group.my_group.self_link] },
    { hosts = ["3.api.example.org", "3.example.org"], groups = [google_compute_instance_group.my_group.self_link] },
    { hosts = [], groups = [google_compute_instance_group.my_group.self_link] },
  ]
}
```

#### Step 2: Remove the service/bucket definitions.

Once this change has been applied, you can then remove the services or buckets:

```hcl
module load_balancer {
  source = "garbetjie/load-balancer/google"
  
  name = "load-balancer" 
  default_backend = ["service", 0]
  health_checks = [google_compute_health_check.my_healthcheck]
  address = google_compute_global_address.my_address.address
  
  buckets = [
    { hosts = ["1.static.example.org"], bucket = google_storage_bucket.my_bucket1.name },
    { hosts = ["3.static.example.org"], bucket = google_storage_bucket.my_bucket1.name },
  ]
  
  services = [
    { hosts = ["api.example.org", "example.org"], groups = [google_compute_instance_group.my_group.self_link] },
    { hosts = ["3.api.example.org", "3.example.org"], groups = [google_compute_instance_group.my_group.self_link] },
  ]
}
```


### Removing a load balancer

When removing the load balancer entirely, the same process needs to be followed as when removing a bucket or service - 
all hosts for the buckets and services need to be set to empty lists.

When this change has been applied, the load balancer can be removed.

**Please note:** You _will_ receive an error when removing the load balancer, where the backend service or bucket that
is set to be the default will not be removed (as it will still be in use by the load balancer). Simply re-planning &
applying your configuration after this should resolve it. 


## Inputs

| Name                  | Description                                                                                                                                                                                                                                         | Type         | Default | Required |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|---------|----------|
| name                  | Name of the load balancer (as displayed in the Google Cloud Console)                                                                                                                                                                                | string       | n/a     | Yes      |
| health_check          | Health check to use on the backend services, to determine health of the service. This health check is used if no health check is specified on a backend service. This is required if any of the backend services don't have a health check defined. | string       | `null`  | No       |
| default_backend       | Backend type and index to select as the default backend. Must be a list with the first index being one of `bucket` or `service`, and the second the index of the bucket or service designated as the default.                                       | list         | n/a     | Yes      |
| address               | IP address to assign to the load balancer.                                                                                                                                                                                                          | string       | n/a     | Yes      |
| services              | List of objects used to define the backend services for the load balancer.                                                                                                                                                                          | list(object) | `[]`    | No       |
| services.hosts        | HTTP hosts for which traffic should be sent to these groups.                                                                                                                                                                                        | list(string) | `[]`    | No       |
| services.groups       | selfLinks of the instance groups to which traffic should be sent.                                                                                                                                                                                   | list(string) | n/a     | Yes      |
| services.health_check | selfLink of a health check to use to determine this service's health. Defaults to `var.health_check` if not defined.                                                                                                                                | string       | `null`  | No       |
| buckets               | List of objects used to define the backend buckets for the load balancer.                                                                                                                                                                           | list(object) | `[]`    | No       |
| buckets.hosts         | HTTP hosts for which traffic should be sent to this bucket.                                                                                                                                                                                         | list(string) | `[]`    | No       |
| buckets.bucket        | The name of the bucket to direct traffic to.                                                                                                                                                                                                        | string       | n/a     | Yes      |


## Outputs

None
