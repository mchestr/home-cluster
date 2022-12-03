# Authentication

## LDAP Configuration

Currently using/testing [LDAP plugin](https://github.com/jellyfin/jellyfin-plugin-ldapauth) for Jellyfin with [Glauth](../../auth-system/glauth/).

The following config is being used, and seems to work ok.
```
<?xml version="1.0" encoding="utf-8"?>
<PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LdapServer>glauth.auth-system.svc.cluster.local</LdapServer>
  <LdapPort>389</LdapPort>
  <UseSsl>false</UseSsl>
  <UseStartTls>false</UseStartTls>
  <SkipSslVerify>false</SkipSslVerify>
  <LdapBindUser>cn=search,ou=svcaccts,dc=home,dc=arpa</LdapBindUser>
  <LdapBindPassword>PASSWORD</LdapBindPassword>
  <LdapBaseDn>dc=home,dc=arpa</LdapBaseDn>
  <LdapSearchFilter>(&amp;(objectClass=posixAccount)(memberOf=ou=media,ou=groups,dc=home,dc=arpa))</LdapSearchFilter>
  <LdapAdminBaseDn />
  <LdapAdminFilter>(&amp;(objectClass=posixAccount)(uid={username})(memberOf=ou=admins,ou=groups,dc=home,dc=arpa))</LdapAdminFilter>
  <LdapSearchAttributes>uid, cn, mail, givenName</LdapSearchAttributes>
  <EnableCaseInsensitiveUsername>false</EnableCaseInsensitiveUsername>
  <CreateUsersFromLdap>true</CreateUsersFromLdap>
  <AllowPassChange>false</AllowPassChange>
  <LdapUsernameAttribute>uid</LdapUsernameAttribute>
  <LdapPasswordAttribute>userPassword</LdapPasswordAttribute>
  <EnableAllFolders>true</EnableAllFolders>
  <EnabledFolders>
    <string>9d7ad6afe9afa2dab1a2f6e00ad28fa6</string>
    <string>f137a2dd21bbc1b99aa5c0f6bf02a805</string>
    <string>a656b907eb3a73532e40e44b968d0225</string>
  </EnabledFolders>
  <PasswordResetUrl />
</PluginConfiguration>
```
