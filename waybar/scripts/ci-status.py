#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

FEED = "http://epbr-cc-tray.s3-website.eu-west-2.amazonaws.com/"
PREFIXES = ("epbr-data-warehouse-pipeline", "epbr-data-frontend-pipeline", "epbr-addressing-pipeline", "epbr-register-api-pipeline")

def fetch(url: str, timeout: int = 8) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "Waybar-CCTray/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()

def parse_projects(xml_bytes: bytes):
    root = ET.fromstring(xml_bytes)
    items = []
    for proj in root.findall("Project"):
        name = proj.attrib.get("name", "")
        prefix = name.split(" :: ", 1)[0]
        if prefix not in PREFIXES:
            continue
        items.append({
            "name": name,
            "prefix": prefix,
            "step": name.split(" :: ", 1)[1] if " :: " in name else "",
            "status": proj.attrib.get("lastBuildStatus", "Unknown"),
            "activity": proj.attrib.get("activity", "Sleeping"),
            "time": proj.attrib.get("lastBuildTime", ""),
            "url": proj.attrib.get("webUrl", ""),
        })
    return items

def icon_for(status: str, activity: str) -> str:
    if activity == "Building":
        return "⏳"
    if status == "Success":
        return "✅"
    if status in ("Failure", "Exception"):
        return "❌"
    return "⚪"

def aggregate_icon(items) -> str:
    if any(i["activity"] == "Building" for i in items):
        return "⏳"
    if any(i["status"] in ("Failure", "Exception") for i in items):
        return "❌"
    return "✅" if items else "∅"

def build_tooltip(items) -> str:
    if not items:
        return "No matching projects"
    lines = []
    for prefix in PREFIXES:
        group = [i for i in items if i["prefix"] == prefix]
        if not group:
            continue
        lines.append(prefix + ":")
        for i in group:
            step = i["step"] or i["name"]
            lines.append(f"  {icon_for(i['status'], i['activity'])} {step} → {i['status']}")
    return "\n".join(lines)

def output_waybar(items):
    payload = {
        "text": aggregate_icon(items),
        "tooltip": build_tooltip(items),
    }
    print(json.dumps(payload, ensure_ascii=False))

def show_menu(items):
    if not items:
        return
    entries = [f"{icon_for(i['status'], i['activity'])} {i['name']} → {i['status']}" for i in items]
    proc = subprocess.Popen(
        ["rofi", "-dmenu", "-p", "CI Pipelines"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    choice, _ = proc.communicate("\n".join(entries))
    choice = choice.strip()
    if choice:
        # Optional: copy the line to clipboard (if wl-copy is available)
        try:
            subprocess.run(["wl-copy"], input=choice, text=True)
        except FileNotFoundError:
            pass

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--menu", action="store_true", help="Show a rofi dropdown instead of Waybar JSON")
    args = parser.parse_args()

    try:
        xml_bytes = fetch(FEED)
        items = parse_projects(xml_bytes)
    except Exception as e:
        # Emit a valid Waybar JSON on error so the bar doesn't break
        print(json.dumps({"text": "⚠️", "tooltip": f"Error: {e}"}))
        sys.exit(0)

    if args.menu:
        show_menu(items)
    else:
        output_waybar(items)

if __name__ == "__main__":
    main()

