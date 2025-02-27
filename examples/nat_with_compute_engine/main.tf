/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# [START vpc_network_nat_gce]
module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 7.0"
  project_id   = var.project_id # Replace this with your project ID in quotes
  network_name = "custom-network1"
  mtu          = 1460

  subnets = [
    {
      subnet_name   = "subnet-us-east-192"
      subnet_ip     = "192.168.1.0/24"
      subnet_region = "us-east4"
    }
  ]
}
# [END vpc_network_nat_gce]

# [START compute_vm_nat_gce]
resource "google_compute_instance" "default" {
  project      = var.project_id
  zone         = "us-east4-c"
  name         = "nat-test-1"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network    = "custom-network1"
    subnetwork = var.subnet # Replace with a reference or self link to your subnet, in quotes
  }
}
# [END compute_vm_nat_gce]


# [START iam_nat_iap_gce]
resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:test123@example.domain.com"
}
# [END iam_nat_iap_gce]

# [START vpc_firewall_nat_gce]
resource "google_compute_firewall" "rules" {
  project = var.project_id
  name    = "allow-ssh"
  network = var.network # Replace with a reference or self link to your network, in quotes

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}
# [END vpc_firewall_nat_gce]

# [START cloudnat_router_nat_gce]
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "nat-router"
  network = var.network
  region  = "us-east4"
}
# [END cloudnat_router_nat_gce]

# [START cloudnat_nat_gce]
module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 3.0"
  project_id                         = var.project_id
  region                             = "us-east4"
  router                             = google_compute_router.router.name
  name                               = "nat-config"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# [END cloudnat_nat_gce]
