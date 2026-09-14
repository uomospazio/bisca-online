# BISCA — browser multiplayer test

Private rooms for 2–8 players, bots, reconnect and a 30-second turn timer.
Open the GitHub Pages link on desktop or a phone in landscape orientation.

## Hosting: FREE ONLY

- GitHub Pages serves `docs/` on the `main` branch.
- Render runs one **Free** Web Service from `Dockerfile`, port 10000.
- No paid database, disk, worker, custom domain, or payment method required.
- Do not upgrade the instance or add billing details. At free limits, stop instead.
- Idle services sleep; the first connection can take around a minute.
- Rooms are held in RAM: a server restart loses active rooms and matches.
- Reconnect works while the same server process and room remain alive.

## Build

Godot 4.7.2 with matching Web export templates, single-thread Compatibility export.
Set `bisca/network/server_url` in `project.godot` to the deployed `wss://` URL.
Run Godot `--headless --editor --import --quit`, then
`--headless --export-release "BISCA Web" docs/index.html`.

## Native LAN and WebSocket testing

The desktop build still supports ENet on UDP 8910 and automatic local hosting.
Start `--headless -- --server --websocket` for WebSocket on port 8910, then
connect clients using `ws://127.0.0.1:8910`. Render terminates TLS and proxies
secure WebSocket to the lightweight Godot rules server.

## Distribution

This repository contains only BISCA's required resources, not the embedded
Lexispell demo or previous exports. The root LICENSE covers the original MIT
UI components; it does not grant a blanket license to third-party art, audio,
or fonts. Their respective rights remain with their owners.
