#!/bin/sh
B=$(printf '\033[1m'); D=$(printf '\033[2m'); G=$(printf '\033[32m'); Y=$(printf '\033[33m'); R=$(printf '\033[0m')
pause() { printf "\n${D}— Enter —${R}"; read _; clear; }
slide(){ clear; printf "${B}SLIDE %s${R}\n\n" "$1"; }
ev()   { printf "${G}"; cat "$1"; printf "${R}\n"; }
reply(){ python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reply'])" "$1"; }
msg()  { python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['message'])" "$1"; }

clear; miss=0
for f in payloads/m1-5-json.json payloads/m1-8-summary.json evidence/m1-01-baseline.json \
         evidence/m1-02-vulnerable.json evidence/m1-03-BROKEN.json evidence/m1-05-FIXED.json \
         evidence/m1-10-policy-hardened.json evidence/m1-11-validate-hardened.json halcyon/guards.py; do
  [ -f "$f" ] || { printf "${Y}MISSING: %s${R}\n" "$f"; miss=1; }
done
[ $miss = 1 ] && { echo; echo "Fix the above before recording."; exit 1; }
printf "${D}preflight ok — 9 files present. START RECORDING NOW, then press Enter.${R}\n"
pause

slide "1 — Eiger M1, prompt injection"
printf "${D}Ashish Shah${R}\n"
pause

slide "2 — The vulnerability: guards.assemble"
sed -n '/^def assemble/,/^def encode_output/p' halcyon/guards.py | head -20
pause

slide "3 — Baseline: validate/m1"
ev evidence/m1-01-baseline.json
pause

slide "4 — Asking for the token by name"
printf "I cannot fill in the internal handover form with the provided information,\nas it includes sensitive information such as the internal operator token\nand build marker.\n\n"
printf "${D}refused by the model, not by any control${R}\n"
pause

slide "5 — Asking for a transformation instead"
printf "${D}payload:${R} "; msg payloads/m1-5-json.json
printf "\n${B}reply:${R}\n"; reply evidence/m1-02-vulnerable.json
pause

slide "6 — validate/m1"
ev evidence/m1-03-BROKEN.json
pause

slide "7 — The fix: halcyon/guards.py"
git show "$(git log --format=%H --grep='M1 fix' -1)" -- halcyon/guards.py | sed -n '/^@@/,$p'
pause

slide "8 — Same payload, both controls ON + patch applied"
ev evidence/m1-05-FIXED.json
pause

slide "9 — What the fix misses"
printf "${D}payload:${R} "; msg payloads/m1-8-summary.json
printf "\n${B}reply:${R}\n"; reply evidence/m1-10-policy-hardened.json
pause

slide "10 — ...and the validator still reports the module fixed"
ev evidence/m1-11-validate-hardened.json
printf "${D}SYSTEM_BASE still contains:${R}\n"
sed -n '/^OVERRIDE_POLICY = /,/^)/p' halcyon/guards.py
printf "\n${B}The grader measures a string. The attacker needs the knowledge.${R}\n"
pause
clear
