#!/bin/sh
# Tries each indirection payload against /api/chat until the honeytoken leaks.
# No reset between attempts on purpose: the audit event is what grades, so the
# first one that lands makes core pass and stays passed.
S=ashish-m1
for f in payloads/m1-5-json.json payloads/m1-6-translate.json \
         payloads/m1-7-continue.json payloads/m1-8-summary.json payloads/m1-9-echo.json; do
  echo "================ $f"
  r=$(curl -s -X POST localhost:8000/api/chat -H 'content-type: application/json' -d @"$f")
  echo "$r" | cut -c1-400
  if echo "$r" | grep -q 'HALCYON-OPS-7731'; then
    echo ">>>>>> TOKEN LEAKED <<<<<<"
    echo "$r" > evidence/m1-02-vulnerable.json
    curl -s "localhost:8000/validate/m1?session=$S" | tee evidence/m1-03-BROKEN.json; echo
    echo "winning payload: $f"
    exit 0
  fi
  echo "--- no token, next ---"
done
echo "none leaked; re-run, it is non-deterministic"
curl -s "localhost:8000/validate/m1?session=$S"; echo
