# MeeraAuth — documentation

| Doc | Topic |
|-----|--------|
| **[USAGE.md](./USAGE.md)** | Host integration guide (start here) |
| **[services/](./services/)** | Per-flow AuthClient → HTTP → JSON |

`AuthFlowNotice` contract and service index: [services/README.md](./services/README.md#authflownotice).

Upstream SSO X API dumps (login, recovery, verification, settings) live outside the Swift package so SPM clones stay lean:

**[docs/sso-reference/](../../../docs/sso-reference/)** (repo root)
