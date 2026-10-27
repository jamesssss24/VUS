#!/usr/bin/env python3
import argparse
import json
import mimetypes
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, quote, unquote, urlsplit

MAX_UPLOAD_BYTES = 1024 * 1024 * 1024
CHUNK_SIZE = 1024 * 1024

PAGE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title>iPad File Transfer</title>
  <style>
    body { font: 16px system-ui, sans-serif; max-width: 760px; margin: 2rem auto; padding: 0 1rem; }
    h1 { font-size: 1.6rem; }
    form, li { margin: 1rem 0; }
    button, input { font: inherit; padding: .6rem; }
    #status { min-height: 1.5em; }
    li { overflow-wrap: anywhere; }
  </style>
</head>
<body>
  <h1>iPad File Transfer</h1>
  <p>Choose files on your iPad to copy them into the VUS desktop. Uploaded files are saved in the desktop's configured iPad transfer folder.</p>
  <form id="upload">
    <input id="files-input" type="file" multiple required>
    <button id="upload-button" type="submit">Upload files</button>
  </form>
  <p id="status" role="status" aria-live="polite"></p>
  <h2>Files in VUS</h2>
  <ul id="files"></ul>
  <script>
    const fileList = document.querySelector("#files");
    const status = document.querySelector("#status");
    const input = document.querySelector("#files-input");
    const button = document.querySelector("#upload-button");

    async function refreshFiles() {
      const response = await fetch("/api/files");
      if (!response.ok) throw new Error("Could not load the file list.");
      const files = await response.json();
      fileList.replaceChildren();
      for (const file of files) {
        const item = document.createElement("li");
        const link = document.createElement("a");
        link.href = "/download/" + encodeURIComponent(file.name);
        link.textContent = file.name;
        const size = document.createElement("span");
        size.textContent = ` (${file.size} bytes)`;
        item.append(link, size);
        fileList.append(item);
      }
      if (files.length === 0) fileList.textContent = "No files uploaded yet.";
    }

    document.querySelector("#upload").addEventListener("submit", async (event) => {
      event.preventDefault();
      if (input.files.length === 0) return;
      button.disabled = true;
      try {
        for (const file of input.files) {
          status.textContent = `Uploading ${file.name}…`;
          const response = await fetch("/upload?filename=" + encodeURIComponent(file.name), {
            method: "POST",
            headers: { "Content-Type": "application/octet-stream" },
            body: file
          });
          const result = await response.json();
          if (!response.ok) throw new Error(result.error || `Upload failed for ${file.name}.`);
        }
        input.value = "";
        status.textContent = "Upload complete.";
        await refreshFiles();
      } catch (error) {
        status.textContent = error.message;
      } finally {
        button.disabled = false;
      }
    });

    refreshFiles().catch((error) => { status.textContent = error.message; });
  </script>
</body>
</html>
"""


class TransferHandler(BaseHTTPRequestHandler):
    server_version = "VUSFileTransfer/1.0"

    @property
    def transfer_dir(self):
        return self.server.transfer_dir

    def send_json(self, status, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        request = urlsplit(self.path)
        if request.path == "/":
            body = PAGE.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
        elif request.path == "/health":
            self.send_json(200, {"status": "ok"})
        elif request.path == "/api/files":
            files = [
                {"name": entry.name, "size": entry.stat(follow_symlinks=False).st_size}
                for entry in self.transfer_dir.iterdir()
                if entry.is_file(follow_symlinks=False)
            ]
            files.sort(key=lambda entry: entry["name"].casefold())
            self.send_json(200, files)
        elif request.path.startswith("/download/"):
            name = unquote(request.path[len("/download/"):])
            if not self.valid_name(name):
                self.send_error(400, "Invalid file name")
                return
            path = self.transfer_dir / name
            if not path.is_file() or path.is_symlink():
                self.send_error(404, "File not found")
                return
            size = path.stat().st_size
            content_type = mimetypes.guess_type(name)[0] or "application/octet-stream"
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(size))
            self.send_header(
                "Content-Disposition",
                f"attachment; filename*=UTF-8''{quote(name)}",
            )
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            with path.open("rb") as source:
                while chunk := source.read(CHUNK_SIZE):
                    self.wfile.write(chunk)
        else:
            self.send_error(404, "Not found")

    def do_POST(self):
        request = urlsplit(self.path)
        if request.path != "/upload":
            self.send_error(404, "Not found")
            return

        try:
            size = int(self.headers.get("Content-Length", ""))
        except ValueError:
            self.send_json(411, {"error": "A valid Content-Length is required."})
            return
        if size < 0:
            self.send_json(400, {"error": "Invalid upload size."})
            return
        if size > MAX_UPLOAD_BYTES:
            self.send_json(413, {"error": "Files must be 1 GiB or smaller."})
            return

        name = parse_qs(request.query, keep_blank_values=True).get("filename", [""])[0]
        if not self.valid_name(name):
            self.send_json(400, {"error": "Invalid file name."})
            return

        path = self.transfer_dir / name
        flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        try:
            descriptor = os.open(path, flags, 0o600)
        except FileExistsError:
            self.send_json(409, {"error": f"{name} already exists."})
            return
        except OSError as error:
            self.send_json(500, {"error": f"Could not create upload: {error.strerror}."})
            return

        remaining = size
        try:
            with os.fdopen(descriptor, "wb") as target:
                while remaining:
                    chunk = self.rfile.read(min(CHUNK_SIZE, remaining))
                    if not chunk:
                        raise ConnectionError("Upload ended before all bytes arrived")
                    target.write(chunk)
                    remaining -= len(chunk)
        except (BrokenPipeError, ConnectionError, OSError):
            path.unlink(missing_ok=True)
            return
        self.send_json(201, {"name": name, "size": size})

    @staticmethod
    def valid_name(name):
        return (
            bool(name)
            and name not in {".", ".."}
            and "/" not in name
            and "\\" not in name
            and "\x00" not in name
            and len(name.encode("utf-8")) <= 255
        )

    def log_message(self, format_string, *args):
        print(f"{self.address_string()} - {format_string % args}", flush=True)


def main():
    parser = argparse.ArgumentParser(description="Serve a private iPad file-transfer page.")
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--port", default=8080, type=int)
    args = parser.parse_args()

    args.directory.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("0.0.0.0", args.port), TransferHandler)
    server.transfer_dir = args.directory.resolve()
    print(f"iPad file transfer listening on port {args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
