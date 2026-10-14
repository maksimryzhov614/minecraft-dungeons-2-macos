#!/bin/bash
# Rollback: return VM to the snapshot taken by tune-vm.sh.
VM="Windows 11"
ID=$(prlctl snapshot-list "$VM" -j | /opt/homebrew/bin/python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(k for k,v in d.items() if v.get("name")=="pre-tune"))') || { echo "snapshot pre-tune not found"; exit 1; }
prlctl snapshot-switch "$VM" -i "$ID" && prlctl start "$VM" 2>/dev/null
echo restored
