# BISCA mobile push notifications

This first slice supports opt-in FCM token registration and server dispatch for incoming friend requests and lobby invitations. Web/Desktop remain unchanged. The app does not send FCM credentials or accept notification content from clients.

## 1. Mobile plugin and Firebase app configuration

The project now includes the MIT-licensed Godotx Firebase 3.1.0 plugin for Godot 4.7, with only Firebase Core and Firebase Messaging modules. iOS XCFrameworks are trimmed to iOS device/simulator slices. The Android Gradle build template is installed locally under the ignored `android/build/` directory; on a fresh clone, use **Project → Install Android Build Template** before exporting.

Register both native app identifiers in a Firebase project matching the export presets:

- Android: `com.bisca.game`; add `google-services.json` as requested by the plugin.
- iOS: `com.uomospazio.bisca.dev`; add `GoogleService-Info.plist` as requested by the plugin.

Download the two client configuration files and keep them at the project root under these exact names: `google-services.json` and `GoogleService-Info.plist`. They are ignored by Git. In Export → Android choose the JSON file; Firebase Core and Messaging are enabled in the Android preset. In Export → iOS choose the plist and ensure the Core/Messaging iOS plugins are enabled. Do not commit private signing keys or service-account JSON. Firebase client config files identify the project but do not authorize sending messages.

The Android Gradle template conditionally applies Google's services plugin when the local JSON config is present. This avoids breaking builds before Firebase is configured. The iOS preset enables the Push Notifications entitlement. APNs setup in Firebase and an Apple Developer team capable of push provisioning are still required for iPhone delivery.

For iOS, upload an APNs authentication key to Firebase and enable Push Notifications in the Apple app identifier/export. This requires an Apple Developer team that supports push entitlements; a free Personal Team may be insufficient for device push testing. Use a physical iPhone for the final test.

## 2. Supabase schema

Run `deployment/supabase/014_push_devices.sql` in the Supabase SQL Editor. It creates a private token table and two RPCs. The client registers only `auth.uid()`; the table itself has no client read/write grants.

## 3. Supabase Edge Function

Deploy `deployment/supabase/functions/push-dispatch/index.ts` as `push-dispatch` with JWT verification disabled because Database Webhooks authenticate using a separate random secret header. Store these secrets in Supabase Function Secrets (never in Godot):

- `FCM_SERVICE_ACCOUNT_JSON`: the Firebase service-account JSON for the same Firebase project.
- `BISCA_PUSH_WEBHOOK_SECRET`: a long random value.

The Supabase runtime provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to the function. Configure Database Webhooks with POST JSON and header `x-bisca-webhook-secret: <the same random value>`:

- `public.bisca_friendships`: INSERT events.
- `public.bisca_lobby_invites`: INSERT and UPDATE events.

Set both webhook destinations to the deployed `push-dispatch` URL. Friend requests are sent only for newly inserted pending rows; expired lobby invitations are ignored. The server resolves recipient devices and sends generic notification text without room codes or account secrets.

## 4. App opt-in and test

Open Settings → General → Push notifications on an iOS/Android build. Grant the operating-system permission. The device token is then registered for the currently connected Supabase account. Create a friendship request or invite from a second test account while the first app is backgrounded. Confirm the push arrives, then open BISCA and inspect Friends; the page refreshes its authoritative state from Supabase.

Token reception/registration can be checked through the `PushNotifications.registration_changed` signal in the Godot debugger. Never print the actual token to logs. If the Firebase native singleton is absent, the setting reports that the mobile plugin is not installed and the rest of the game continues normally.

## Remaining setup / limitations

The native modules and app wiring are in place, but this repository does not contain either Firebase client config file, APNs credentials, Firebase service-account secret, deployed Supabase function, or database webhooks. Until those are configured, registration/dispatch cannot be tested end-to-end. The current plugin API reports foreground message receipt, but this version does not yet route a notification tap directly to the Friends page; on tap, the user can open BISCA and use the existing Friends list, which refreshes from Supabase.
