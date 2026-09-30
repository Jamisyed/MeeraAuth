# MeeraAuth — Service docs

Host-facing reference for **MeeraAuth** (Swift 6, headless) against MeeraSpace SSO X **App Client / API mode**.

Each file maps: **purpose → AuthClient APIs → HTTP → decision tree → sample Swift → JSON**.

Upstream full dumps: [docs/sso-reference/](../../../docs/sso-reference/).  
Integration guide: [USAGE.md](../USAGE.md).

| Doc | Flow | Who picks email vs SMS / OTP path |
|-----|------|-----------------------------------|
| [login.md](./login.md) | AAL1 password + AAL2 MFA | **Server** `active` (`mfases` / `mfasms`) |
| [biometric.md](./biometric.md) | Biometric login + settings bind/unbind | Host supplies key / name / identifier |
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

MeeraAuth does **not** render SSO `ui` forms. It parses `ui` only for `flowTokenId`, identifier hints, and flow `messages`.

Web Client / cookie browser flows are **out of scope** for this SDK.

### AuthFlowNotice

SSO flow `messages` are split by **`type`**:

| Server `type` | SDK behavior |
|---------------|--------------|
| `"info"` / `"success"` | Returned as `[AuthFlowNotice]` (or result `.notices`) — **not** thrown |
| `"error"` | Mapped to thrown `AuthError` |

Typical info codes: `2000` success, `6062` code sent, `6063` code resent, `6065` code completed, `6048` identity verified.

```swift
let notices = try await auth.sendLoginMFA()
showInfo(notices.first?.localizedDescription)
```

Empty `notices` is normal — use a host fallback string.
