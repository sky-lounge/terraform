variable "gcp_project" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "cloud_run_domain" {
  type = string
}

variable "cloud_run_location" {
  type = string
}

variable "cloud_run_service_name" {
  type = string
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.53, < 5.0"
    }
  }
  backend "gcs" {}
  required_version = ">= 0.13"
}

provider "google" {
  project = var.gcp_project
}

data "google_dns_managed_zone" "zone" {
  name = var.dns_zone_name
}

data "google_cloud_run_service" "crs" {
  name     = var.cloud_run_service_name
  location = var.cloud_run_location
}

resource "google_dns_record_set" "a" {
  name         = "${var.cloud_run_domain}."
  managed_zone = data.google_dns_managed_zone.zone.name
  type         = "A"
  ttl          = 300
  rrdatas = ["8.8.8.8"]
}

resource "google_cloud_run_domain_mapping" "crdm" {
  location = var.cloud_run_location
  name     = var.cloud_run_domain

  spec {
    route_name = data.google_cloud_run_service.crs.name
  }
}
