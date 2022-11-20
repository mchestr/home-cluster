### Terraform Setup

I am using [Terraform Cloud](https://app.terraform.io/) to store the `tfstate` of the app, mostly following others in the [k8s-at-home](https://github.com/k8s-at-home) community setup as an example!
To initialize TF Cloud run the following in each module.

```
terraform init
```

The TF Controller which periodically applies this infrastructure can be found in [tf-controller](../../cluster/apps/flux-system/tf-controller/) directory, along with all the secrets.
