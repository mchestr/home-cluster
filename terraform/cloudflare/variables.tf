variable "cloudflare_email" {
  type        = string
  description = "Cloudflare Email Address"
}
variable "cloudflare_apikey" {
  type        = string
  description = "Cloudflare Account API Key"
}
variable "cloudflare_domain" {
  type        = string
  description = "Cluster domain"
}
variable "aws_ses_cname1" {
  type        = string
  description = "AWS SES CNAME 1"
}
variable "aws_ses_cname1_value" {
  type        = string
  description = "AWS SES CNAME 1 value"
}
variable "aws_ses_cname2" {
  type        = string
  description = "AWS SES CNAME 2"
}
variable "aws_ses_cname2_value" {
  type        = string
  description = "AWS SES CNAME 2 value"
}
variable "aws_ses_cname3" {
  type        = string
  description = "AWS SES CNAME 3"
}
variable "aws_ses_cname3_value" {
  type        = string
  description = "AWS SES CNAME 3 value"
}
