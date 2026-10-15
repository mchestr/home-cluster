variable "zones" {
  type        = list(string)
  description = "Zones served through the cluster's tunnel; every zone gets the same settings and firewall rules"
  default     = ["chestr.dev", "mikeflix.lol"]
}

variable "cloudflare_api_token" {
  type = string
  description = "Cloudflare API Token"
}

variable "onepassword_url" {
  type = string
  description = "Onepassword URL"
}

variable "onepassword_token" {
  type = string
  description = "Onepassword Token"
}
