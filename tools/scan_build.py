import re, sys, os

ROOT = r"C:\Users\Dmitriy\Desktop\Project FeatherCage"

targets = [
    os.path.join(ROOT, "HNRenovated", "Binaries", "Win64", "HNRenovated-Win64-Shipping.exe"),
    os.path.join(ROOT, "Project Feathercage.exe"),
]

pats = [
    re.compile(rb"\+{2}UE4\+Release-[ -~]{0,40}"),
    re.compile(rb"4\.2[0-9]\.[0-9]+"),
    re.compile(rb"UnrealEngine[ -~]{0,30}"),
    re.compile(rb"UE4-[ -~]{0,20}"),
    re.compile(rb"(?i)encryption ?key[ -~]{0,80}"),
    re.compile(rb"(?i)aes[ -~]{0,60}"),
    re.compile(rb"(?i)pak[ -~]{0,30}"),
]

for t in targets:
    if not os.path.exists(t):
        print("MISSING", t)
        continue
    b = open(t, "rb").read()
    print("=" * 20, t, len(b))
    # ascii
    for p in pats:
        found = sorted(set(m.group(0) for m in p.finditer(b)))
        shown = [x[:100] for x in found[:12]]
        if shown:
            print("  %-28s %s" % (p.pattern.decode(), shown))
    # utf16le
    u = b.decode("utf-16-le", errors="ignore").encode("latin-1", errors="ignore")
    for p in pats[:5]:
        found = sorted(set(m.group(0) for m in p.finditer(u)))
        if found:
            print("  UTF16 %-22s %s" % (p.pattern.decode(), [x[:100] for x in found[:8]]))
