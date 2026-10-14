#!/bin/bash
# One command: snapshot, Mac-side VM tuning, Windows debloat/telemetry/Defender off.
# Rollback: ./restore-vm.sh
set -u
VM="Windows 11"; DIR="$(cd "$(dirname "$0")" && pwd)"; SNAP="pre-tune"; G="${1:-tune-guest.ps1}"
prlctl list "$VM" >/dev/null 2>&1 || { echo "VM '$VM' not found"; exit 1; }
[ "$(prlctl list "$VM" -o status | tail -1 | tr -d ' ')" = running ] || { echo "Start VM first: prlctl start \"$VM\""; exit 1; }

if prlctl snapshot-list "$VM" -j 2>/dev/null | grep -q "\"$SNAP\""; then echo "snapshot $SNAP exists, keeping"; else
  echo "[1/4] snapshot $SNAP"; prlctl snapshot "$VM" -n "$SNAP" -d "before tune-vm.sh" || exit 1; fi

echo "[2/4] Mac-side VM settings: already tuned (4 CPU, 8 GB, 3D highest), nothing to change"

echo "[3/4] push script into guest"
until prlctl exec "$VM" whoami >/dev/null 2>&1; do sleep 2; done
B64=$(base64 < "$DIR/$G" | tr -d '\n')
prlctl exec "$VM" powershell -NoProfile -Command "Remove-Item C:\\Windows\\Temp\\tune.b64 -EA 0" >/dev/null 2>&1
# long command lines fail in prlctl exec, so send 2000-char chunks
while [ -n "$B64" ]; do
  prlctl exec "$VM" powershell -NoProfile -Command "Add-Content -Path C:\\Windows\\Temp\\tune.b64 -Value ${B64:0:2000} -NoNewline" || exit 1
  B64=${B64:2000}
done
prlctl exec "$VM" certutil -f -decode C:\\Windows\\Temp\\tune.b64 C:\\Windows\\Temp\\tune.ps1 >/dev/null || exit 1

echo "[4/4] run in guest (2-5 min)"
prlctl exec "$VM" powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Windows\\Temp\\tune.ps1 | tail -15
echo "--- Defender status"
prlctl exec "$VM" powershell -NoProfile -Command "Get-MpComputerStatus | select RealTimeProtectionEnabled,IsTamperProtected | fl | Out-String"
echo "Reboot Windows to finish: prlctl restart \"$VM\"   Guest log: C:\\Windows\\Temp\\tune.log"
