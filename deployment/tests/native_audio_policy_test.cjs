// Source-level contract only; native builds and physical-device tests are also required.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const android = fs.readFileSync(path.join(root, 'addons/bisca_voice/android/plugin/src/main/java/com/uomospazio/bisca/voice/BiscaVoicePlugin.kt'), 'utf8');
const ios = fs.readFileSync(path.join(root, 'deployment/ios/BiscaVoice.swift'), 'utf8');
assert.match(android, /audioOutputType\s*=\s*AudioType\.MediaAudioType\(\)/);
assert.match(android, /volumeControlStream\s*=\s*AudioManager\.STREAM_MUSIC/);
assert.doesNotMatch(android, /AudioType\.CallAudioType\(|MODE_IN_COMMUNICATION/);
for (const option of ['echoCancellation', 'autoGainControl', 'noiseSuppression']) {
  assert.match(ios, new RegExp(`${option}: true`));
  assert.match(ios, new RegExp(`${option}Mode: \\.software`));
}
assert.match(ios, /RoomOptions\(defaultAudioCaptureOptions: capture\)/);
assert.match(ios, /isAutomaticDeactivationEnabled = false/);
assert.match(ios, /setCategory\(settings\.0, mode: settings\.1, options: settings\.2\)/);
assert.doesNotMatch(ios, /isVoiceProcessingBypassed\s*=\s*true|AudioCaptureOptions\.noProcessing/);
console.log('PASS: native media audio policy and iOS microphone processing/restoration contract');
