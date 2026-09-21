# Vendored browser dependency

- Package: `livekit-client@2.22.3` from the npm registry (official LiveKit client).
- File: `scenes/balatro/scripts/livekit-client.umd.js`, copied unmodified from `dist/`.
- SHA-256: `7fa17e37af5e996d8a25f15a637dcc0620215bc01b394e5d209f726afe7dc04d`.
- License: Apache-2.0, complete text in `LIVEKIT-LICENSE` and `docs/LIVEKIT-LICENSE.txt`.
- Loaded locally from the Godot PCK before the voice bridge; no runtime CDN dependency.
- Update explicitly, retest the bridge, record version/hash, and rebuild the Web export.
- Uses Web Audio mixing for per-player volume on iOS; no AI agent, recording,
  transcription, video, or external analytics integration is enabled by Bisca.
