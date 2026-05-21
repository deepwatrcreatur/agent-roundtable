#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: ./scripts/vaglio-post-deploy-smoke.sh [proxmox_host] [router_host] [ctid]

Read-only smoke check to run after a Vaglio deploy.

Defaults:
  proxmox_host = root@10.10.11.55
  router_host  = root@10.10.10.1
  ctid         = 104
EOF
  exit 0
fi

proxmox_host="${1:-root@10.10.11.55}"
router_host="${2:-root@10.10.10.1}"
ctid="${3:-104}"

printf '=== vaglio post-deploy smoke ===\n'
printf 'proxmox host: %s\nrouter host: %s\nctid: %s\n\n' "$proxmox_host" "$router_host" "$ctid"

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

for demo in forgejo kubernetes nixpkgs; do
  printf '\n=== %s demo markers ===\n' "$demo"
  ssh "$router_host" "curl -k --max-time 30 -s 'https://roundtable.deepwatercreature.com/forgejo-shell?demo=$demo' | rg -n 'Sampled Repo Evidence|Top sampled contributors|Recent sampled commits|Sampled path hotspots|Selected demo details' -n || true"
done
