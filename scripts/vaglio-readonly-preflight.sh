#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/vaglio-readonly-preflight.sh [proxmox_host] [ctid]

Read-only coordination check before any live Vaglio deploy.

Defaults:
  proxmox_host = root@10.10.11.55
  ctid         = 104
EOF
  exit 0
fi

host="${1:-root@10.10.11.55}"
ctid="${2:-104}"

printf '=== vaglio readonly preflight ===\n'
printf 'proxmox host: %s\nctid: %s\n\n' "$host" "$ctid"

ssh "$host" "
  pct status $ctid
  printf '\n---\n'
  pct exec $ctid -- sh -lc '
    hostname
    systemctl is-active roundtable || true
    systemctl is-active roundtable-prewarm-public-repo-cache || true
    ps -ef | grep -E \"nixos-rebuild|switch-to-configuration|roundtable-prewarm|beam.smp\" | grep -v grep || true
    printf \"\n---\n\"
    find /var/lib/roundtable -maxdepth 4 \\( -name .setup-lock -o -name .roundtable-source-rev -o -name .roundtable-deps-rev -o -name .roundtable-toolchain-ready \\) -print 2>/dev/null | sort
  '
"
