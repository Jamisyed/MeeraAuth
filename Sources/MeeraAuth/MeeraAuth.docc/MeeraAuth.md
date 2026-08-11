# ``MeeraAuth``

Headless Swift 6 authentication for MeeraSpace SSO X (App Client / API mode).

## Overview

MeeraAuth owns auth flows, errors, session, and tokens. Host apps own UI and HTTP transport via ``AuthHTTPClient``.

## Topics

### Essentials

- ``AuthClient``
- ``AuthConfiguration``
- ``AuthError``

### Configuration

- ``AuthResourceTemplates``
- ``MFAPolicy``
- ``LoginOption``
- ``AuthScope``
- ``AuthLocale``

### Models

- ``RegistrationProfile``
- ``RegistrationStep``
- ``LoginStep``
- ``TokenSet``
- ``Session``

### Host ports

- ``AuthHTTPClient``
- ``TokenStore``
- ``SessionStore``

## See also

Host integration guide: `Docs/USAGE.md` in the package repository.
