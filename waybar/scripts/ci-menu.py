#!/usr/bin/env python3
import requests
import xml.etree.ElementTree as ET
import subprocess
import sys

FEED = "http://epbr-cc-tray.s3-website.eu-west-2.amazonaws.com/"

# Pipelines of interest
FILTER = ["epbr-data-warehouse-pipeline", "epbr-data-frontend-pipeline", "epbr-addressing-pipeline"]

def fetch_xml(url):
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    return resp.content

def parse_projects(xml_bytes):
    root = ET.fromstring(xml_bytes)
    projects = []
    for proj in root.findall("Project"):
        name = proj.attrib.get("name", "")
        if any(f in name for f in FILTER):
            status = proj.attrib.get("lastBuildStatus", "Unknown")
            activity = proj.attrib.get("activity", "Sleeping")
            url = proj.attrib.get("webUrl", "")
            projects.append((name, status, activity, url))
    return projects

def status_icon(status, activity):
    if activity == "Building":
        return "⏳"
    if status == "Success":
        return "✅"
    if status == "Failure":
        return "❌"
    return "⚪"

def show_rofi_menu(projects):
    menu_entries = []
    for name, status, activity, url in projects:
        icon = status_icon(status, activity)
        menu_entries.append(f"{icon} {name} → {status} | {url}")

    rofi = subprocess.Popen(
        ["rofi", "-dmenu", "-p", "CI Pipelines"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )
    choice, _ = rofi.communicate("\n".join(menu_entries))
    return choice.strip()

def open_url(choice):
    if not choice:
        return
    parts = choice.split("|", 1)
    if len(parts) == 2:
        url = parts[1].strip()
        if url:
            print(url)
            subprocess.Popen(["xdg-open", url])

def main():
    try:
        xml_bytes = fetch_xml(FEED)
        projects = parse_projects(xml_bytes)
        if not projects:
            sys.exit(0)
        choice = show_rofi_menu(projects)
        print(choice)
        open_url(choice)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

