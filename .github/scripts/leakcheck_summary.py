# Prints the outcome of each Chrome password leak check in a net-log.
import json, sys, datetime

d = json.load(open(sys.argv[1]))
offset = int(d["constants"].get("timeTickOffset", 0))
reqs = {}
for e in d["events"]:
    p = e.get("params", {})
    if "leaks:lookupSingle" in str(p.get("url", "")):
        reqs.setdefault(e["source"]["id"], {"t": int(e["time"])})
for e in d["events"]:
    r = reqs.get(e["source"]["id"])
    h = e.get("params", {}).get("headers")
    if r is not None and isinstance(h, list) and h and str(h[0]).startswith("HTTP/"):
        r["status"] = h[0]
for r in sorted(reqs.values(), key=lambda r: r["t"]):
    if "status" in r:
        ts = datetime.datetime.fromtimestamp((r["t"] + offset) / 1000, datetime.timezone.utc)
        print(f"[leak-check] {ts.strftime('%H:%M:%S.%f')[:-3]} {r['status']}")
print(f"[leak-check] total={sum(1 for r in reqs.values() if 'status' in r)}")
