#!/usr/bin/env python3
import argparse
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen


PAGE_PATH = Path(__file__).with_name("audio-receiver.html")


class AudioReceiverHandler(BaseHTTPRequestHandler):
    upstream_url = ""

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", "3")
            self.end_headers()
            self.wfile.write(b"ok\n")
            return

        if self.path in ("/", "/index.html", "/audio-receiver.html"):
            self._send_page()
            return

        if self.path == "/audio.mp3":
            self._proxy_audio()
            return

        self.send_error(404, "Not found")

    def do_HEAD(self):
        if self.path in ("/", "/index.html", "/audio-receiver.html"):
            try:
                page_size = PAGE_PATH.stat().st_size
            except OSError as error:
                self.send_error(500, f"Could not read the audio receiver page: {error}")
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(page_size))
            self.end_headers()
            return

        self.send_error(404, "Not found")

    def _send_page(self):
        try:
            page = PAGE_PATH.read_bytes()
        except OSError as error:
            self.send_error(500, f"Could not read the audio receiver page: {error}")
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(page)

    def _proxy_audio(self):
        upstream = None
        last_error = None
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            try:
                upstream = urlopen(self.upstream_url, timeout=10)
                break
            except (OSError, URLError) as error:
                last_error = error
                time.sleep(0.5)

        if upstream is None:
            self.log_error("Could not connect to the desktop audio stream: %s", last_error)
            self.send_error(502, "Desktop audio stream is not ready")
            return

        with upstream:
            self.send_response(upstream.status)
            self.send_header(
                "Content-Type",
                upstream.headers.get("Content-Type", "audio/mpeg"),
            )
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            while True:
                try:
                    chunk = upstream.read1(64 * 1024)
                except OSError as error:
                    self.log_error("Desktop audio stream ended unexpectedly: %s", error)
                    break
                if not chunk:
                    break
                try:
                    self.wfile.write(chunk)
                    self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    self.log_message("Audio client disconnected")
                    break

    def log_message(self, format_string, *args):
        print(f"audio-receiver: {self.address_string()} - {format_string % args}")


def main():
    parser = argparse.ArgumentParser(description="Serve the desktop audio receiver.")
    parser.add_argument("--port", type=int, default=6082)
    parser.add_argument(
        "--upstream",
        default="http://127.0.0.1:6081/audio.mp3",
        help="Local FFmpeg stream URL",
    )
    args = parser.parse_args()
    AudioReceiverHandler.upstream_url = args.upstream

    server = ThreadingHTTPServer(("0.0.0.0", args.port), AudioReceiverHandler)
    print(f"audio-receiver: serving on port {args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
