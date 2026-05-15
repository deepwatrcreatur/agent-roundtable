#!/usr/bin/env bash
set -euo pipefail

host="${1:-root@10.10.11.55}"
ctid="${2:-104}"

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
