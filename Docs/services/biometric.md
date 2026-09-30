# Biometric service

**AuthClient:** `AuthClient+Biometric`  
**Domain:** `BiometricFlowService` · **Requests:** `LoginRequest.submitBiometric`, `SettingsRequest.bindBiometric` / `unbindBiometric`  
**SSO ref:** [x-login-flow.md](../../../docs/sso-reference/x-login-flow.md) (biometric form), settings Civil ID doc (biometric form + `unlinkKey`)

---

## 1. Purpose

SSO biometric login and settings bind/unbind. The host owns Face ID / Touch ID, UUID `biometricAuthKey` storage, device `name`, and identifier. MeeraAuth only talks to SSO.

---

## 2. AuthClient APIs

| Method | Role | Returns |
|--------|------|---------|
| `startBiometricLogin()` | `GET {SSO_X}/login/api` | — |
| `loginWithBiometric(identifier:name:biometricAuthKey:)` | `POST` `method: biometric` | `LoginStep` |
| `startBiometricSettings()` | `GET {SSO_X}/settings/api` (needs session) | — |
| `settingsBindBiometric(...)` | Register key | `[AuthFlowNotice]` |
| `settingsUnbindBiometric(...)` | Remove key (`unlinkKey: true`) | `[AuthFlowNotice]` |

SSO body always sets `"method": "biometric"` (host does not pass method).

---

## 3. Host responsibilities

| Concern | Owner |
|---------|--------|
| `LocalAuthentication` (Face ID / Touch ID) | Host |
| Generate / store `biometricAuthKey` (UUID) | Host |
| `name` (e.g. `"Jadarah-faceID"`) | Host |
| `identifier` (email / mobile) | Host |
| `isBiometricEnabled` flag | Host |
| Bind / unbind / biometric login HTTP | MeeraAuth |

---

## 4. Sequences

### Login

```text
startBiometricLogin
→ loginWithBiometric(identifier, name, biometricAuthKey)
→ LoginStep (.authenticated or .requiresMFA)
→ exchangeTokens() when authenticated
```

If MFA is required after biometric login, use the same `sendLoginMFA` / `verifyLoginMFA` APIs (MeeraAuth routes to the biometric MFA state when active).

### Enable (bind)

```text
Face ID success → new UUID
→ startBiometricSettings
→ settingsBindBiometric(identifier, name, key)
→ host: isBiometricEnabled = true
```

### Disable (unbind)

```text
startBiometricSettings
→ settingsUnbindBiometric(identifier, name, key)
→ host: clear local key / enabled flag
```

---

## 5. Sample host Swift

```swift
// Login
try await auth.startBiometricLogin()
let step = try await auth.loginWithBiometric(
    identifier: storedEmailOrMobile,
    name: "Jadarah-faceID",
    biometricAuthKey: storedUUID
)
switch step {
case .authenticated(_, let notices):
    _ = notices
    let tokens = try await auth.exchangeTokens()
case .requiresMFA(_, _, let notices):
    _ = notices
    let result = try await auth.verifyLoginMFA(code: otp)
    let tokens = try await auth.exchangeTokens()
}

// Bind (logged in)
try await auth.startBiometricSettings()
_ = try await auth.settingsBindBiometric(
    identifier: email,
    name: "Jadarah-faceID",
    biometricAuthKey: newUUID
)

// Unbind
try await auth.startBiometricSettings()
_ = try await auth.settingsUnbindBiometric(
    identifier: email,
    name: "Jadarah-faceID",
    biometricAuthKey: storedUUID
)
```
