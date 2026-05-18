## Round 51 — Q38: NPTv6 Implementation

**Tags:** tooling, structural, hosting, infrastructure
**Status:** Closed  
**Voices used:** Codex CLI, Gemini CLI  
**Claude:** Used as IC for synthesis

### Round question

Q38.1 — Share difficulties with NPTv6 implementation and get distinct agent perspectives. Why is the 'npt' keyword failing, and what are the best alternatives for achieving 1:1 prefix translation in a NixOS environment?

### Voice summaries

#### Codex (Structural Architect)

- [observed] The `npt` failure is a parser/syntax mismatch. Official `nftables` documentation points to `snat ip6 prefix to` rather than a standalone `npt` keyword.
- [inferred] Best NixOS path: Use `snat ip6 prefix to <external-prefix>/<len>` in `postrouting`.
- [inferred] Avoid custom packet mangling in raw/mangle chains unless strict statelessness is a hard requirement.

#### Gemini (Analytical Specialist)

- [observed] The current implementation in `modules/router-nptv6.nix` lacks the `prefix` keyword, causing it to behave as Many-to-One Masquerade rather than 1:1 NPTv6.
- [inferred] The canonical fix is `snat ip6 prefix to ${rule.externalPrefix}`.
- [inferred] This requires `nftables >= 1.0.5` and `Linux kernel >= 5.8`, which are met in modern NixOS.
- [satisfied] The "Stateful Fallback" label currently in use is a workaround for the syntax error, not a fundamental architectural requirement.

### IC Synthesis

**Consensus:** The council identifies the `npt` keyword as a non-standard symbol that triggers a parser error in `nftables`. The correct, RFC 6296-compliant way to perform 1:1 prefix translation in `nftables` is to use the `prefix` keyword within `snat` and `dnat` statements.

**Implementation Rules:**
1. Update `router-nptv6.nix` to use `snat ip6 prefix to ${rule.externalPrefix}`.
2. Remove the "Stateful Fallback" comments as the updated syntax provides the intended 1:1 mapping.
3. Keep the rules in the `nat` table to leverage the kernel's built-in checksum neutrality for prefix translation.

`[satisfied]`
