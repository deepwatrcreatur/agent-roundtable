# 25 — Authentik OIDC Authentication

**Status:** `done`
**Assigned:** Codex

## Scope

Add authentication to the LiveView dashboard via Authentik as OIDC broker
with GitHub as the upstream social provider (Q25 decision).

## Architecture

```
Browser → Phoenix LiveView
             ↓ assent OIDC
         Authentik (OIDC issuer)
             ↓ social login
         GitHub OAuth
```

The roundtable app is an OIDC relying party to Authentik; GitHub identity
is available as a claim in the OIDC token without the app needing its own
GitHub OAuth client.

## Implementation steps

1. Add `assent` to `mix.exs`:
   ```elixir
   {:assent, "~> 0.2"}
   ```

2. Add `RoundtableWeb.AuthController` with `callback/2` and `sign_in/2` actions.

3. Add session assign `:current_user` (map with `:github_login`, `:email`).

4. Add `on_mount` hook to `DiscussionLive` that redirects to `/auth/sign_in`
   when `:current_user` is absent.

5. Repo permission gate: after sign-in, call
   `GET /repos/:owner/:repo/collaborators/:username` with the service PAT
   to verify the user has at least `read` access.

## Environment variables

| Var | Description |
|---|---|
| `OIDC_ISSUER_URL` | Authentik OIDC issuer URL (homelab) |
| `OIDC_CLIENT_ID` | OIDC client ID registered in Authentik |
| `OIDC_CLIENT_SECRET` | OIDC client secret |
| `GITHUB_SERVICE_PAT` | Service token for repo permission checks |

When `OIDC_ISSUER_URL` is unset, the dashboard runs unauthenticated
(localhost dev mode).

## Notes

- Local Authentik account usable as fallback when GitHub is unreachable
- Telegram identity binding stored as custom Authentik attribute — not a
  roundtable app concern
