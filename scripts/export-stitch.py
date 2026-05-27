#!/usr/bin/env python3
"""Re-exporta telas e assets do Google Stitch via MCP HTTP."""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STITCH_DIR = ROOT / "design" / "stitch"
EXPORTS_DIR = STITCH_DIR / "exports"
SCREENS_DIR = STITCH_DIR / "screens"
ASSETS_DIR = STITCH_DIR / "assets"
MOBILE_DESIGN = ROOT / "mobile" / "assets" / "design" / "DESIGN.md"
MCP_URL = "https://stitch.googleapis.com/mcp"
PROJECT_ID = "14895410954006795741"

SKIP_TITLE_PREFIXES = ("PRD",)


def slugify(title: str) -> str:
    s = title.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def mcp_call(api_key: str, tool: str, arguments: dict) -> dict:
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {"name": tool, "arguments": arguments},
    }
    req = urllib.request.Request(
        MCP_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": api_key,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = json.load(resp)

    if body.get("error"):
        raise RuntimeError(f"MCP error: {body['error']}")

    result = body.get("result") or {}
    if result.get("isError"):
        text = (result.get("content") or [{}])[0].get("text", "unknown error")
        raise RuntimeError(text)

    return result


def parse_tool_json(result: dict) -> dict:
    content = result.get("content") or []
    if not content:
        return result.get("structuredContent") or {}
    text = content[0].get("text")
    if not text:
        return result.get("structuredContent") or {}
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return result.get("structuredContent") or {}


def download(url: str, dest: Path) -> int:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "btwobet-export/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    return len(data)


def extract_image_urls(html: str) -> list[str]:
    urls = set(re.findall(r'https://lh3\.googleusercontent\.com/[^"\')\s]+', html))
    return sorted(urls)


def asset_filename(url: str, index: int) -> str:
    digest = hashlib.sha256(url.encode()).hexdigest()[:12]
    return f"img-{index:02d}-{digest}.png"


def main() -> int:
    api_key = os.environ.get("STITCH_API_KEY", "").strip()
    if not api_key:
        print("Defina STITCH_API_KEY no ambiente.", file=sys.stderr)
        return 1

    EXPORTS_DIR.mkdir(parents=True, exist_ok=True)
    SCREENS_DIR.mkdir(parents=True, exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    print("Listando telas...")
    list_result = mcp_call(api_key, "list_screens", {"projectId": PROJECT_ID})
    listed = parse_tool_json(list_result)
    screens_meta = listed.get("screens") or []

    manifest = {
        "project": {"title": "Bolão Copa do Mundo 2026", "id": PROJECT_ID},
        "screens": [],
        "assets": [],
    }

    all_image_urls: dict[str, str] = {}

    for item in screens_meta:
        title = item.get("title") or "Untitled"
        if any(title.startswith(p) for p in SKIP_TITLE_PREFIXES):
            print(f"  pulando: {title}")
            continue

        name = item.get("name") or ""
        screen_id = name.split("/")[-1] if name else item.get("screenId")
        if not screen_id:
            continue

        slug = slugify(title)
        print(f"Exportando: {title} ({screen_id})")

        raw_result = mcp_call(
            api_key,
            "get_screen",
            {"projectId": PROJECT_ID, "screenId": screen_id},
        )
        (SCREENS_DIR / f"{slug}.json").write_text(
            json.dumps(raw_result, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        screen = parse_tool_json(raw_result)
        if not screen:
            screen = raw_result.get("structuredContent") or {}

        export_dir = EXPORTS_DIR / slug
        export_dir.mkdir(parents=True, exist_ok=True)

        html_path = export_dir / "index.html"
        screenshot_path = export_dir / "screenshot.png"
        html_bytes = 0
        image_bytes = 0

        html_url = (screen.get("htmlCode") or {}).get("downloadUrl")
        if html_url:
            html_bytes = download(html_url, html_path)
            html = html_path.read_text(encoding="utf-8", errors="replace")
            for i, url in enumerate(extract_image_urls(html), start=1):
                all_image_urls.setdefault(url, asset_filename(url, i))

        shot_url = (screen.get("screenshot") or {}).get("downloadUrl")
        if shot_url:
            image_bytes = download(shot_url, screenshot_path)

        manifest["screens"].append(
            {
                "title": title,
                "slug": slug,
                "screenId": screen_id,
                "width": screen.get("width"),
                "height": screen.get("height"),
                "deviceType": screen.get("deviceType"),
                "htmlPath": str(html_path.relative_to(ROOT)),
                "imagePath": str(screenshot_path.relative_to(ROOT)),
                "htmlBytes": html_bytes,
                "imageBytes": image_bytes,
            }
        )

    print(f"Baixando {len(all_image_urls)} imagens do HTML...")
    asset_map: dict[str, str] = {}
    for url, filename in all_image_urls.items():
        dest = ASSETS_DIR / filename
        try:
            size = download(url, dest)
            asset_map[url] = str(dest.relative_to(ROOT))
            manifest["assets"].append(
                {"sourceUrl": url, "path": str(dest.relative_to(ROOT)), "bytes": size}
            )
            print(f"  ok {filename} ({size} bytes)")
        except urllib.error.URLError as exc:
            print(f"  falha {filename}: {exc}", file=sys.stderr)

    print("Exportando design system...")
    ds_result = mcp_call(api_key, "list_design_systems", {"projectId": PROJECT_ID})
    ds_data = parse_tool_json(ds_result)
    (STITCH_DIR / "design-system" / "design-systems.json").parent.mkdir(
        parents=True, exist_ok=True
    )
    (STITCH_DIR / "design-system" / "design-systems.json").write_text(
        json.dumps(ds_data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    if ds_data.get("designSystems"):
        ds = ds_data["designSystems"][0].get("designSystem") or {}
        guidelines = ds.get("styleGuidelines") or ""
        if guidelines:
            (STITCH_DIR / "design-system" / "style-guidelines.md").write_text(
                guidelines, encoding="utf-8"
            )

    manifest["assetMap"] = asset_map
    (STITCH_DIR / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    if (STITCH_DIR / "DESIGN.md").exists() and MOBILE_DESIGN.parent.exists():
        MOBILE_DESIGN.parent.mkdir(parents=True, exist_ok=True)
        MOBILE_DESIGN.write_text(
            (STITCH_DIR / "DESIGN.md").read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        print(f"Copiado DESIGN.md -> {MOBILE_DESIGN.relative_to(ROOT)}")

    # Hero do painel de palpites para o Flutter
    hero_candidates = [
        ASSETS_DIR / f
        for f in sorted(os.listdir(ASSETS_DIR))
        if f.endswith(".png")
    ] if ASSETS_DIR.exists() else []

    painel_html = EXPORTS_DIR / "painel-de-palpites" / "index.html"
    if painel_html.exists():
        html = painel_html.read_text(encoding="utf-8", errors="replace")
        hero_match = re.search(
            r'<img[^>]+alt="World Cup Stadium"[^>]+src="([^"]+)"', html
        )
        if hero_match:
            hero_url = hero_match.group(1)
            hero_local = asset_map.get(hero_url)
            if hero_local:
                mobile_hero_dir = ROOT / "mobile" / "assets" / "images"
                mobile_hero_dir.mkdir(parents=True, exist_ok=True)
                src = ROOT / hero_local
                dest = mobile_hero_dir / "hero-stadium.png"
                dest.write_bytes(src.read_bytes())
                print(f"Hero copiado -> {dest.relative_to(ROOT)}")

    print("Export concluído.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
