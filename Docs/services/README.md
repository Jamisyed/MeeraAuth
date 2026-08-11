# MeeraAuth — Service docs

Host-facing reference for **MeeraAuth** (Swift 6, headless) against MeeraSpace SSO X **App Client / API mode**.

Each file maps: **purpose → AuthClient APIs → HTTP → decision tree → sample Swift → JSON**.

Upstream full dumps: [docs/sso-reference/](../../../docs/sso-reference/).  
Integration guide: [USAGE.md](../USAGE.md).

| Doc | Flow | Who picks email vs SMS / OTP path |
|-----|------|-----------------------------------|
| [login.md](./login.md) | AAL1 password + AAL2 MFA | **Server** `active` (`mfases` / `mfasms`) |
| [registration.md](./registration.md) | Basic + Civil ID signup | Host step sequence (`signupOptions`) |
| [verification.md](./verification.md) | Activate email / mobile | **Host** `MFAChannel` |
| [recovery.md](./recovery.md) | Forgot password | **Host** `LoginOption` |
| [tokens.md](./tokens.md) | Exchange + refresh | N/A |
| [settings.md](./settings.md) | Password / Civil ID / contact | Host steps + session |
| [session-logout.md](./session-logout.md) | Session helpers + logout | N/A |

### Conventions

| Placeholder | Meaning |
|-------------|---------|
| `{SSO_X}` | `AuthConfiguration.ssoXEndpoint` |
| `{SSO}` | `AuthConfiguration.ssoEndpoint` |
| `X-SESSION-ID` | App Client session header (not browser cookies) |

MeeraAuth does **not** render SSO `ui` forms. It parses `ui` only for `flowTokenId`, identifier hints, and error `messages`.

Web Client / cookie browser flows are **out of scope** for this SDK.
