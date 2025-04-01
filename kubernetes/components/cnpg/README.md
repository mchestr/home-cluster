## CloudNative PG

### Populate Secrets for new App

```
export APP=sonarr
PASSWORD=$(op item create --category password --generate-password=letters,digits,20 --dry-run --format json | jq -r '.fields[0].value')
op item edit cloudnative-pg "${APP}_postgres_username[text]=${APP}"
op item edit cloudnative-pg "${APP}_postgres_password[password]=${PASSWORD}"
```
