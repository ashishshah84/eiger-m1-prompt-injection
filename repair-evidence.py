import json, re, sys, pathlib
def repair(p):
    raw = p.read_text()
    try:
        json.loads(raw); return "ok"
    except Exception:
        pass
    m = re.search(r'\{\s*"reply"\s*:\s*"(.*)"\s*\}\s*\Z', raw, re.S)
    if not m:
        return "UNRECOVERABLE"
    body = m.group(1).replace('\\"', '"').replace('\\\\', '\\')
    p.write_text(json.dumps({"reply": body}, indent=2))
    return "repaired"
for a in sys.argv[1:]:
    p = pathlib.Path(a)
    for f in (sorted(p.glob("*.json")) if p.is_dir() else [p]):
        print(f"{f}: {repair(f)}")
