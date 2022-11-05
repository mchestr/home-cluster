# Postgres

### Notes

Useful commands if permission issues
```
\c authentik
GRANT ALL PRIVILEGES ON DATABASE authentik to <user>;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public to <user>;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO <user>;
```
