# INPUTS

variable "json_key" {}
variable "project_id" {}
variable "region" {
  default = "us-west1"
}
variable "zone" {
  default = "us-west1-a"
}
variable "env_name" {}
variable "internal_cidr" {
  default = "10.0.0.0/16"
}

variable "dns_zone_name" {}
variable "dns_json_key" {}
variable "dns_project_id" {}
variable "system_domain_suffix" {}

# RESOURCES

provider "google" {
  credentials = "${var.json_key}"
  project = "${var.project_id}"
  region = "${var.region}"
}

provider "google" {
  alias = "dns"
  credentials = "${var.dns_json_key}"
  project = "${var.dns_project_id}"
  region = "${var.region}"
}

resource "google_compute_network" "default" {
  name = "${var.env_name}"
}

resource "google_compute_subnetwork" "default" {
  name = "${var.env_name}"
  ip_cidr_range = "${var.internal_cidr}"
  network = "${google_compute_network.default.self_link}"
}

resource "google_compute_firewall" "default" {
  name = "${var.env_name}"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["25555", "22", "6868", "443", "80", "4443", "8443", "8844"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["${var.env_name}"]
}

resource "google_compute_address" "default" {
  name = "${var.env_name}"
}

resource "google_dns_record_set" "default" {
  provider = "google.dns"
  name = "*.${var.env_name}.${var.system_domain_suffix}."
  type = "A"
  ttl = 300

  managed_zone = "${var.dns_zone_name}"
  rrdatas = [ "${google_compute_address.default.address}" ]
}

# OUTPUTS

output "external_ip" {
  value = "${google_compute_address.default.address}"
}

output "system_domain" {
  value = "${var.env_name}.${var.system_domain_suffix}"
}

output "network" {
  value = "${google_compute_network.default.name}"
}

output "subnetwork" {
  value = "${google_compute_subnetwork.default.name}"
}

output "zone" {
  value = "${var.zone}"
}

output "tags" {
  value = "${google_compute_firewall.default.target_tags}"
}

output "project_id" {
  value = "${var.project_id}"
}

output "internal_ip" {
  value = "${cidrhost("${google_compute_subnetwork.default.ip_cidr_range}", 6)}"
}

output "internal_gw" {
  value = "${cidrhost("${google_compute_subnetwork.default.ip_cidr_range}", 1)}"
}

output "internal_cidr" {
  value = "${google_compute_subnetwork.default.ip_cidr_range}"
}
