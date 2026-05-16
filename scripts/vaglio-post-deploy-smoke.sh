#!/usr/bin/env bash
set -euo pipefail

proxmox_host="${1:-root@10.10.11.55}"
router_host="${2:-root@10.10.10.1}"
ctid="${3:-104}"

ssh "$proxmox_host" "
  pct status $ctid
  printf '\n---\n'
  pct exec $ctid -- sh -lc '
    systemctl is-active roundtable
    systemctl is-active roundtable-prewarm-public-repo-cache || true
    ss -ltnp | grep 4000 || true
    printf \"\n---\n\"
    ls -la /var/lib/roundtable/state/public-repo-cache 2>/dev/null || true
  '
"

printf '\n=== public route ===\n'
ssh "$router_host" "curl -k -I --max-time 15 https://roundtable.deepwatercreature.com/forgejo-shell"

printf '\n=== kubernetes demo markers ===\n'
ssh "$router_host" "curl -k --max-time 20 -s 'https://roundtable.deepwatercreature.com/forgejo-shell?demo=kubernetes' | rg -n 'Sampled Repo Evidence|Top sampled contributors|Recent sampled commits|Sampled path hotspots|Selected demo details' -n || true"
