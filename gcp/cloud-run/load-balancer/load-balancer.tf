/**
 * Copyright 2020 Google LLC
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

module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.2.0"
  name    = "${var.service_name}-lb"
  project = var.gcp_project_id

  ssl                             = var.ssl
  managed_ssl_certificate_domains = [var.domain]
  https_redirect                  = var.ssl

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}

data "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.gcp_region
  project  = var.gcp_project_id
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "${var.service_name}-serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region
  cloud_run {
    service = data.google_cloud_run_service.service.name
  }
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = data.google_cloud_run_service.service.location
  project  = data.google_cloud_run_service.service.project
  service  = data.google_cloud_run_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

data "google_dns_managed_zone" "zone" {
  name = var.dns_zone_name
}

resource "google_dns_record_set" "a" {
  name         = "${var.domain}."
  managed_zone = data.google_dns_managed_zone.zone.name
  type         = "A"
  ttl          = 300

  rrdatas = [module.lb-http.external_ip]
}


