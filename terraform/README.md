# Terraform Setup

The Cloudflare workspace (`terraform/cloudflare`) stores its state in [Terraform Cloud](https://app.terraform.io/), organization `mchestr`, workspace `cloudflare`. The Cloudflare and 1Password Connect credentials come from workspace variables.

Run it through the Taskfile:

```bash
task terraform:cf:init
task terraform:cf:plan
task terraform:cf:apply
```
