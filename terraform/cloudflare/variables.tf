variable "cluster_domain" {
  type = string
  description = "Cluster Domain Name"
  default = "chestr.dev"
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
