# BISCA Android voice bridge

Android uses the same authenticated voice-token request and `BiscaVoice`
GDScript adapter as the other platforms. `BiscaVoicePlugin.kt` is the Android
LiveKit transport; the voice token continues to come from the BISCA game
server, so no LiveKit secret is embedded in the app.

## Build the Android plugin AAR

The Godot editor project expects the generated plugin at
`addons/bisca_voice/bin/bisca_voice.aar`. Build it from the repository root
with JDK 17+ and Gradle 8.13:

```sh
gradle -p addons/bisca_voice/android :plugin:assembleRelease
mkdir -p addons/bisca_voice/bin
cp addons/bisca_voice/android/plugin/build/outputs/aar/plugin-release.aar \
  addons/bisca_voice/bin/bisca_voice.aar
```

The AAR is a generated build artifact and is not committed. LiveKit's Android
SDK is resolved by the Godot Android Gradle export as a pinned Maven dependency.

## Godot Android export

The project enables this editor export plugin, turns on `Use Gradle Build`, and
requests the Android `RECORD_AUDIO` permission. In Godot, install the Android
build template if it is not already installed, configure the Android SDK and
Java SDK paths in Editor Settings, then export/run the Android preset. On first
Gradle export, allow Gradle to resolve dependencies from Maven Central and
JitPack.

The app asks for microphone access only after the player explicitly enables
voice in a multiplayer lobby. Voice is stopped when the app is backgrounded,
the lobby is changed, or the game is closed; it does not record in the
background.

## Device verification

Export/install a new APK after building the AAR. Join the same lobby from an
Android device and another device/browser, enable voice on both, and verify
two-way speech. Also check permission denied/retry, mute/unmute, per-player and
master volume, Bluetooth/headphone routing, app background/foreground, and
leaving/rejoining a lobby. An export build alone cannot verify a real device's
microphone routing or LiveKit connectivity.
