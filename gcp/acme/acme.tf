variable "acme_provider_url" {
  type        = string
  description = "The url of the acme provider used to fetch certificates. This is usually Let's Encrypt: [Production] https://acme-v02.api.letsencrypt.org/directory or [Staging] https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "acme_registration_email" {
  type        = string
  description = "The email address to use for registration with the acme provider."
}

# variable "acme_dns_challenge_provider" {
#   type        = string
#   description = "The name of the dns challenge provider to prove domain ownership. The list of valid providers is available here: https://registry.terraform.io/providers/vancluever/acme/latest/docs."
# }

variable "domain_name" {
  type        = string
  description = "The name of the domain to fetch a certificate for. When using Let's Encrypt, this can be a wildcard domain."
}

variable "alternate_domain_names" {
  type        = list(string)
  default     = [""]
  description = "A list of alternate domain names that should be valid for the certificate."
}

variable "gcp_project_name" {
  type        = string
  description = "The gce project name where the DNS registration exists."
}

variable "gcp_service_account_json_file_path" {
  type        = string
  description = "Path to the credentials file of the service account to use to complete these actions. The service account must have the `DNS Administrator` role."
}

terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
  }
}

provider "acme" {
  server_url = var.acme_provider_url
}

resource "tls_private_key" "registration_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.registration_private_key.private_key_pem
  email_address   = var.acme_registration_email
}

resource "acme_certificate" "certificate" {
  account_key_pem       = acme_registration.registration.account_key_pem
  common_name           = var.domain_name
  recursive_nameservers = ["8.8.8.8:53", "8.8.4.4:53"]
  # subject_alternative_names = var.alternate_domain_names

  dns_challenge {
    provider = "gcloud"
    config = {
      GCE_PROJECT              = var.gcp_project_name
      GCE_SERVICE_ACCOUNT_FILE = var.gcp_service_account_json_file_path
    }
  }
}

output "private_key_pem" {
  value       = acme_certificate.certificate.private_key_pem
  description = "The private key."
}

output "certificate_pem" {
  value       = acme_certificate.certificate.certificate_pem
  description = "The public key."
}

output "issuer_pem" {
  value       = acme_certificate.certificate.issuer_pem
  description = "The signing key"
}
