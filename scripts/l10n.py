#!/usr/bin/env python3
"""String catalog helper.
  l10n.py missing   — keys the last build extracted that have no ko/ja translation in scripts/translations.json
  l10n.py generate  — writes TripPick/Localizable.xcstrings and TripPick/InfoPlist.xcstrings (fails if anything is missing)
Source language is English; the key is the English text."""
import json, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parent.parent
TRANS = ROOT / "scripts/translations.json"
LANGS = ["ko", "ja", "zh-Hans"]

def extracted():
    keys = set()
    for f in (ROOT / ".build/DerivedData").rglob("*.stringsdata"):
        if "TripPick.build" not in str(f):
            continue
        data = json.loads(f.read_text())
        for entry in data.get("tables", {}).get("Localizable", []):
            keys.add(entry["key"])
    return keys

def load():
    return json.loads(TRANS.read_text()) if TRANS.exists() else {"strings": {}, "infoPlist": {}}

def unit(value):
    if isinstance(value, dict):  # {"one": "...", "other": "..."} -> plural variations
        return {"variations": {"plural": {k: {"stringUnit": {"state": "translated", "value": v}} for k, v in value.items()}}}
    return {"stringUnit": {"state": "translated", "value": value}}

def catalog(entries, extract_state=None):
    strings = {}
    for key in sorted(entries):
        tr = entries[key]
        loc = {lang: unit(tr[lang]) for lang in LANGS if lang in tr}
        if "en" in tr:
            loc["en"] = unit(tr["en"])
        item = {"localizations": loc}
        if extract_state:
            item["extractionState"] = extract_state
        strings[key] = item
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}

def main():
    t = load()
    keys = extracted()
    missing = sorted(k for k in keys if k not in t["strings"] or any(l not in t["strings"][k] for l in LANGS))
    if sys.argv[1] == "missing":
        print(json.dumps(missing, ensure_ascii=False, indent=1))
        return
    if missing:
        print("missing translations:", missing); sys.exit(1)
    unused = sorted(k for k in t["strings"] if k not in keys)
    if unused:
        print("unused keys (kept as manual):", unused)
    (ROOT / "TripPick/Localizable.xcstrings").write_text(
        json.dumps(catalog(t["strings"]), ensure_ascii=False, indent=2, sort_keys=True))
    (ROOT / "TripPick/InfoPlist.xcstrings").write_text(
        json.dumps(catalog(t["infoPlist"]), ensure_ascii=False, indent=2, sort_keys=True))
    print(f"wrote {len(t['strings'])} strings")

main()
