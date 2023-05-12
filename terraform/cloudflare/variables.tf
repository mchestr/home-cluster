variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare Account API Token"
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
variable "cloudflared_tunnel_account_id" {
  type        = string
  description = "Cloudflared Tunnel Account ID"
}
variable "cloudflared_tunnel_secret" {
  type        = string
  description = "Cloudflared Tunnel Secret"
}
