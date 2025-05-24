# Authelia OAuth2 Secrets

## Populate Secrets for a New App

Use the following script to generate and store OAuth2 secrets for a new application:

```bash
# Set the application name
export APP=AUTOBRR_TEST

# Generate a client ID
CLIENT_ID=$(docker run --rm authelia/authelia:latest authelia crypto rand --length 72 --charset rfc3986 | awk '{print $3}')

# Generate client secret and hash
CLIENT_SECRET_OUTPUT=$(docker run authelia/authelia:latest authelia crypto hash generate argon2 --random --random.length 64 --random.charset alphanumeric)
CLIENT_SECRET=$(echo $CLIENT_SECRET_OUTPUT | cut -f 3 -d ' ')
CLIENT_SECRET_HASH=$(echo $CLIENT_SECRET_OUTPUT | sed '2p;d' | cut -f 2 -d ' ')

# Store credentials in 1Password
op item edit authelia "${APP}_OAUTH_CLIENT_ID[password]=${CLIENT_ID}"
op item edit authelia "${APP}_OAUTH_CLIENT_SECRET[password]=${CLIENT_SECRET}"
op item edit authelia "${APP}_OAUTH_CLIENT_SECRET_HASH[password]=${CLIENT_SECRET_HASH}"
```
