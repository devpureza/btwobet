#!/usr/bin/env python3
from __future__ import annotations

import argparse
import http.server
import os
import socketserver
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


class SpaFallbackHandler(http.server.SimpleHTTPRequestHandler):
    """
    Serve a static directory like a SPA:
    - if a requested path doesn't exist as a file, fall back to /index.html
    """

    backend_origin = "http://localhost:8080"

    def _proxy_to_backend(self) -> None:
        target = urllib.parse.urljoin(self.backend_origin, self.path)
        body = None
        if "Content-Length" in self.headers:
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                length = 0
            if length > 0:
                body = self.rfile.read(length)

        headers = {}
        for k, v in self.headers.items():
            lk = k.lower()
            if lk in {"host", "content-length", "connection"}:
                continue
            headers[k] = v

        req = urllib.request.Request(
            url=target,
            data=body,
            headers=headers,
            method=self.command,
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    lk = k.lower()
                    if lk in {"transfer-encoding", "connection"}:
                        continue
                    self.send_header(k, v)
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for k, v in e.headers.items():
                lk = k.lower()
                if lk in {"transfer-encoding", "connection"}:
                    continue
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(502)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(f"Proxy error: {e}".encode("utf-8"))

    def do_OPTIONS(self) -> None:  # noqa: N802
        if self.path.startswith(("/api", "/storage", "/flags")):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Authorization,Content-Type,Accept")
            self.end_headers()
            return
        return super().do_OPTIONS()

    def do_GET(self) -> None:  # noqa: N802 (match base class)
        if self.path.startswith(("/api", "/storage", "/flags")):
            return self._proxy_to_backend()
        path = self.translate_path(self.path)
        if Path(path).is_file():
            return super().do_GET()

        # Fallback to index.html for client-side routes (e.g. /login)
        self.path = "/index.html"
        return super().do_GET()

    def do_POST(self) -> None:  # noqa: N802
        if self.path.startswith(("/api", "/storage", "/flags")):
            return self._proxy_to_backend()
        return super().do_POST()

    def do_PUT(self) -> None:  # noqa: N802
        if self.path.startswith(("/api", "/storage", "/flags")):
            return self._proxy_to_backend()
        return super().do_PUT()

    def do_PATCH(self) -> None:  # noqa: N802
        if self.path.startswith(("/api", "/storage", "/flags")):
            return self._proxy_to_backend()
        return super().do_PATCH()

    def do_DELETE(self) -> None:  # noqa: N802
        if self.path.startswith(("/api", "/storage", "/flags")):
            return self._proxy_to_backend()
        return super().do_DELETE()

    def log_message(self, format: str, *args) -> None:  # noqa: A002
        # Keep terminal noise low; still useful enough for dev
        return super().log_message(format, *args)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", default="build/web", help="Directory to serve")
    parser.add_argument("--port", type=int, default=4173, help="Port to listen on")
    parser.add_argument(
        "--backend",
        default="http://localhost:8080",
        help="Backend origin for /api, /storage, /flags proxy (default: http://localhost:8080)",
    )
    args = parser.parse_args()

    root = Path(args.dir).resolve()
    if not root.exists():
        raise SystemExit(f"Directory not found: {root}")

    os.chdir(root)
    SpaFallbackHandler.backend_origin = args.backend
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", args.port), SpaFallbackHandler) as httpd:
        print(f"Serving SPA from {root} at http://localhost:{args.port}")
        print(f"Proxying /api, /storage, /flags -> {args.backend}")
        httpd.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

