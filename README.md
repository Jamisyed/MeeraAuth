# MeeraAuth

Headless Swift 6 authentication SDK for MeeraSpace SSO X (**App Client / API mode**).

Designed for multiple iOS host apps: Clean Architecture, injectable HTTP, Keychain tokens, no UI.

**→ Full guide with examples:** [Docs/USAGE.md](./Docs/USAGE.md)

**→ Per-service flows + JSON:** [Docs/services/](./Docs/services/)

**→ SSO X API reference (repo):** [docs/sso-reference/](../../docs/sso-reference/)

License: [MIT](./LICENSE)

## Quick start

```swift
import MeeraAuth

let auth = AuthClient(
    configuration: AuthConfiguration(
        ssoEndpoint: URL(string: "https://sso.test10.meeraspace.com")!,
        ssoXEndpoint: URL(string: "https://sso.test10.meeraspace.com/x")!,
        clientId: .mobileApp,
        scopes: [.openid, .email, .mobile, .groups, .profile, .offlineAccess],
        locale: .english,
        loginOptions: [.email, .phone, .civilId],
        signupOptions: [.basic, .civilId],
        resources: AuthResourceTemplates(
            emailOTP: "{sso}{emailOtpTmpl}",
            mobileOTP: "{sso}{mobileOtpTmpl}",
            resetEmail: "{sso}{resetEmailTmpl}",
            resetMobile: "{sso}{resetMobileTmpl}",
            activeEmail: "{sso}{activeEmailTmpl}",
            activeMobile: "{sso}{activeMobileTmpl}"
        )
    ),
    httpClient: URLSessionAuthHTTPClient()
)

try await auth.startLogin()
let step = try await auth.login(option: .email, identifier: email, password: password)

switch step {
case .authenticated:
    break
case .requiresMFA:
    _ = try await auth.verifyLoginMFA(code: otp)
}

let tokens = try await auth.exchangeTokens()
```

## Architecture

```
Host apps (UI + TFNetwork adapter)
        ↓
   AuthClient (public facade, actor)
        ↓
 Login / Registration / Recovery / Verification / Settings
        ↓
 AuthRequest enums → SSOAPIClient.execute
        ↓
   AuthHTTPClient (port)  ← inject in host
        ↓
   SSO X API
```

Internal networking mirrors Elevate `RequestProtocol`: typed request enums build path / params; the host still supplies HTTP.

### Source groups

```
Public/
  Client/            AuthClient.swift
  Client/Extensions/ AuthClient+Events|Session|Login|Registration|…
  Configuration/
  Models/Login|Registration|Session/
  Errors/            AuthError (LocalizedError) + AuthErrorCatalog.json in Resources/
Domain/
  Flows/Login|Registration|Recovery|Verification|Settings/
  Tokens/  Client/
Data/
  Requests/Core/
  Requests/Login|Registration|Recovery|Verification|Settings|Token|Logout/
  Client/  Parsing/
Infrastructure/
  Networking/  Support/  Storage/
```

## Login options

| Option | SSO `method` |
|--------|----------------|
| `.email` | `password` |
| `.phone` | `password` |
| `.civilId` | `civilid` |

## Network logging (host-controlled)

The host decides whether MeeraAuth prints SSO calls as `curl`:

```swift
AuthConfiguration(
    …,
    networkLogging: .log       // curl + response (secrets redacted)
    // networkLogging: .verbose // full secrets + response (local debug only)
    // networkLogging: .curl    // curl command only (copy-paste)
    // networkLogging: .off     // default
)
```

Example console output:

```text
━━━━━━━━ MeeraAuth · START · log ━━━━━━━━
→ REQUEST
POST https://sso…/x/login?flow=…
$ curl -v \
	-X POST \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	-d "{\"email\":\"user@example.com\",\"password\":\"[redacted]\",\"method\":\"password\"}" \
	"https://sso…/x/login?flow=…"

← RESPONSE  HTTP 200 · 42ms · 348 B
{
  "…" : "…"
}
━━━━━━━━━━━━ MeeraAuth · END ━━━━━━━━━━━━
```

## Build / test

```bash
cd Packages/MeeraAuth
swift build
swift test
```
