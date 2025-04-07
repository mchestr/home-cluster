## Authelia OAuth2 Secrets

### Populate Secrets for new App

```
export APP=AUTOBRR_TEST
CLIENT_ID=$(docker run --rm authelia/authelia:latest authelia crypto rand --length 72 --charset rfc3986 | awk '{print $3}')
CLIENT_SECRET_OUTPUT=$(docker run authelia/authelia:latest authelia crypto hash generate argon2 --random --random.length 64 --random.charset alphanumeric)
CLIENT_SECRET=$(echo $CLIENT_SECRET_OUTPUT | cut -f 3 -d ' ')
CLIENT_SECRET_HASH=$(echo $CLIENT_SECRET_OUTPUT | sed '2p;d' | cut -f 2 -d ' ')
op item edit authelia "${APP}_OAUTH_CLIENT_ID[password]=${CLIENT_ID}"
op item edit authelia "${APP}_OAUTH_CLIENT_SECRET[password]=${CLIENT_SECRET}"
op item edit authelia "${APP}_OAUTH_CLIENT_SECRET_HASH[password]=${CLIENT_SECRET_HASH}"
```
