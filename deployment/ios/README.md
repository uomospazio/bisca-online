# Native iOS voice

`BiscaVoice.swift` implements the LiveKit transport. `BiscaVoice.mm` registers
the Godot `Engine` singleton `BiscaVoice`. These files are compiled into the
exported application's target; the engine archive does not need rebuilding.
`setup.py` persists the Xcode integration across new Godot exports.

## Reproduce the integration

Requirements: macOS, Xcode 16.3 or newer (verified toolchain: Xcode 26.5), Python
3.9+, the **official Godot 4.7.2** iOS export, and network access for SPM.

```sh
git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot.git /private/tmp/bisca-voice-godot
git -C /private/tmp/bisca-voice-godot rev-parse HEAD
# Must print ed1daf0bf001b61586d9930840f2f1394092c079

# Run from the bisca-online repository root, after exporting from Godot:
python3 deployment/ios/setup.py /path/to/Bisca.xcodeproj \
  --godot-source /private/tmp/bisca-voice-godot --engine-target template_debug

xcodebuild -project /path/to/Bisca.xcodeproj -scheme Bisca \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/bisca-voice-build CODE_SIGNING_ALLOWED=NO build
```

Use a fresh destination for the clone if that directory already exists, or reuse
it after checking its commit. The setup refuses any other Godot source commit.
Pass `--engine-target template_release` for a Godot release export. This must
match the archive's actual object names, which the script verifies; choosing
Xcode Release does **not** turn a Godot debug archive into a release archive.
The `DEBUG_ENABLED` define changes Godot's internal C++ ABI. Do not substitute
older headers or arbitrarily change this define. Custom engine builds require
their exact configuration and are not supported by this setup.

Rerun setup after every new export, or after moving the repository/header checkout.
It references these repository sources by absolute path, generates required
headers with Godot's own generators, adds SPM, adds the microphone usage string,
and adds calls to the exported native initialization/deinitialization hooks.
It preserves other plugins and the existing SDL workaround in `dummy.cpp`.
First-run backups sit alongside the modified Xcode project and `dummy.cpp`.
It does not change or export `Bisca.pck`, Godot scripts, signing, or provisioning.
The pack still needs the native GDScript adapter from the main task.

This uses a post-export source integration rather than shipping a prebuilt
`.gdip` archive. Although newer Godot plugin documentation describes SPM package
metadata, the pinned 4.7.2 exporter source used here does not contain that
dependency parser. The Xcode package reference is explicit and reproducible.

## Dependency pins

LiveKit Swift **2.17.0**, commit
`f07831a7f06bca9e2fc2e136db591b7b42f16d8d`, is an exact SPM requirement.
Its resolved binary dependencies are WebRTC `150.7871.2`
(`c73deceaddd9c07293871ae28f24d4326cc86d62`) and LiveKit UniFFI `0.1.9`
(`7a9bf91b1601d5c408ae0cac7dc2047b5a4f615e`). Xcode writes `Package.resolved`
inside the exported project's workspace. SPM supplies the SDK resources and
embedded binary frameworks. Source API checks were made against this exact tag.

## Adapter contract

`invoke(method: String, args_json: String)` accepts a JSON **array** of positional
arguments; `drain() -> String` returns a JSON array and empties the bounded event
queue. Commands are dispatched FIFO onto the main actor; drain is thread safe.

| Method | JSON arguments |
| --- | --- |
| `update` | `[room, me, roster]` |
| `start` / `stop` | `[]` |
| `credentials` | `[requestId, {"url":"wss://…", "token":"…"}]` or server error dictionary |
| `setMuted` | `[boolean]` |
| `setVolume` | `[playerId, volumeFrom0To1]` |
| `setMaster` | `[volumeFrom0To1]` |

Events match the browser transport:
`{"op":"token","id":number}` and
`{"op":"status","text":string,"enabled":boolean,"pending":boolean,"muted":boolean}`.
The existing authenticated game server supplies credentials in response to token
events. No API secret, alternate token endpoint, or embedded credentials exist.
Credential waits time out after 12 seconds. Stop/lobby changes invalidate request
IDs, permission callbacks, and connection work. New sessions await old teardown.
SDK error details, tokens, and URLs are not forwarded into status messages.

Only explicit `start` requests permission/connects. Updates never auto-start.
Remote identities use the prefix before `.`. Auto-subscription is disabled;
only audio from connected, non-bot peers in the current roster is subscribed.
Per-person gain is multiplied by master gain. Rapid mute updates are serialized.
Backgrounding, audio interruption, lobby changes, and native deinitialization
stop voice; no background voice mode is added and foregrounding never auto-starts.

LiveKit manages duplex audio with speaker preference (`defaultToSpeaker`) and
Bluetooth/A2DP support. The bridge does not force a physical speaker override.
Automatic session deactivation is disabled so Godot audio can continue; the
previous category, mode, options and buffer duration are restored after teardown.

## Device acceptance checks

Verified 2026-10-01: unsigned `Debug-iphoneos` arm64 build succeeded with
Xcode 26.5 against the existing `/private/tmp/bisca-ios-SZlWjY/Bisca.xcodeproj`.
Artifact: `VoiceBuild/Build/Products/Debug-iphoneos/Bisca.app` beneath that export.
Build log: `/private/tmp/bisca-voice-build.log`. The final executable contains
`bisca_voice_initialize`, `bisca_voice_deinitialize` and the Swift bridge class;
the app embeds `LiveKitWebRTC.framework` and `RustLiveKitUniFFI.framework` and
contains the microphone permission description. No Swift bridge actor/delegate
warnings were reported. Godot headers emit existing integer-conversion warnings;
the exported bridging header emits a `#pragma once` warning.

An unsigned build proves compilation/linkage, not microphone or network behavior.
Install a signed build with the latest pack and test an iPhone with a web peer:

1. In a lobby, enable voice; allow permission and confirm bidirectional audio.
2. Deny permission and verify the settings guidance and absence of a connection.
3. Check mute/unmute, person/master gain, and game sounds during and after voice.
4. Test built-in speaker, wired headphones and Bluetooth route changes.
5. Stop during permission/token/connect, switch lobbies, background, and interrupt
   with a call; stale credentials must not restart voice or leave capture running.
6. Disconnect/reconnect the network and leave the lobby; verify status and cleanup.

The temporary exported Xcode project is a build artifact. Keep this directory
in source control and rerun the setup for future exports.
