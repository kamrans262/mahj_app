# Mahj Around Town — Google Sign-In on iPhone

## What the native iOS app needs

1. In Google Cloud Console -> APIs & Services -> Credentials, use the project that owns Mahj's Google OAuth configuration.
2. Create or locate an **iOS OAuth client** for the exact Runner bundle ID (currently `com.example.mahjApp` in `ios/Runner.xcodeproj/project.pbxproj`; change the client registration if the bundle ID changes).
3. Copy the iOS client ID and its **iOS URL scheme (reversed client ID)** from Google Cloud. The scheme normally starts with `com.googleusercontent.apps.`.
4. Locate the **Web application OAuth client ID** that is configured as `GOOGLE_SIGN_IN_CLIENT_ID` on the deployed Laravel backend. It must be used as the iOS **server client ID**; the Laravel verifier validates the Google ID token `aud` against it.
5. On the developer Mac, copy `ios/Flutter/GoogleSignIn.xcconfig.example` to `ios/Flutter/GoogleSignIn.xcconfig` and fill in all three values:
   - `GOOGLE_SIGN_IN_IOS_CLIENT_ID` — iOS OAuth client ID.
   - `GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID` — Google-provided iOS URL scheme.
   - `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` — Web OAuth client ID from Laravel.
6. Run `flutter pub get` and rebuild the **iOS** app; an existing installed app must be rebuilt/reinstalled for native Info.plist changes to take effect.

`GoogleSignIn.xcconfig` is excluded by `.gitignore`. Don't commit private deployment configuration. OAuth client IDs are public identifiers, but keeping platform settings local avoids committing values from the wrong project. **Do not paste API secret keys in the file.**

`ios/Runner/Info.plist` now uses these Xcode build settings for `GIDClientID`, `GIDServerClientID`, and the Google callback URL scheme. The existing `mahjaroundtown` billing callback is preserved. The Debug and Release Xcode configurations optionally include the local file.

The Dart `GoogleAuthService` supports optional `--dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID=...` and `--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...` overrides, but **these do not register an iOS URL scheme**. The native config remains required. With the native Info.plist configured, Dart does not need these overrides.

## Verify

- In the built app Info.plist, confirm GIDClientID and GIDServerClientID are resolved, not `$(...)` or placeholders; ensure CFBundleURLSchemes contains both `mahjaroundtown` and the Google reversed client ID.
- On iPhone, tap Continue with Google, choose an account, and verify login completes and returns to Mahj.
- If Google account selection succeeds but the app shows `The Google account could not be verified for Mahj`, verify the Web client ID in this file matches Laravel `GOOGLE_SIGN_IN_CLIENT_ID`.
- If the OAuth screen cannot open or return to the app, verify the iOS bundle identifier, client ID and reversed scheme.
- Do not change Firebase Maps keys or the production Stripe configuration as part of this fix.
