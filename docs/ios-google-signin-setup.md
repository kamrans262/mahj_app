# Mahj Around Town — Google Sign-In on iPhone

## What the native iOS app needs

1. In Google Cloud Console -> APIs & Services -> Credentials, use the project that owns Mahj's Google OAuth configuration.
2. Create or locate an **iOS OAuth client** for the exact Runner bundle ID (`fun.aroundtown.mahjaroundtown` in `ios/Runner.xcodeproj/project.pbxproj`).
3. The iOS client ID and reversed URL scheme are already taken from `ios/Runner/GoogleService-Info.plist` and written into `Info.plist`. The scheme is `com.googleusercontent.apps.93837877939-eb06m9b3rka5ubf0v212ijus5uu2tqqh`.
4. Locate the **Web application OAuth client ID** that is configured as `GOOGLE_SIGN_IN_CLIENT_ID` on the deployed Laravel backend. It must be used as the iOS **server client ID**; the Laravel verifier validates the Google ID token `aud` against it.
5. On the developer Mac, copy `ios/Flutter/GoogleSignIn.xcconfig.example` to `ios/Flutter/GoogleSignIn.xcconfig` and set `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` to the Web OAuth client ID from Laravel. `Info.plist` already has the iOS client ID and reversed URL scheme from `GoogleService-Info.plist`.
6. Run `flutter pub get` and rebuild the **iOS** app; an existing installed app must be rebuilt/reinstalled for native Info.plist changes to take effect.

`GoogleSignIn.xcconfig` is excluded by `.gitignore`. Don't commit private deployment configuration. **Do not paste API secret keys in the file.**

`ios/Runner/Info.plist` keeps `GIDServerClientID` as the Xcode build setting `$(GOOGLE_SIGN_IN_SERVER_CLIENT_ID)`. `GIDClientID` and the Google callback URL scheme are set from the Firebase iOS app. The `mahjaroundtown` billing callback is preserved. Debug and Release optionally include the local xcconfig.

The Dart `GoogleAuthService` supports optional `--dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID=...` and `--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...` overrides, but **these do not register an iOS URL scheme**. The native config remains required. With the native Info.plist configured, Dart does not need these overrides.

## Verify

- In the built app Info.plist, confirm GIDClientID and GIDServerClientID are resolved, not `$(...)` or placeholders; ensure CFBundleURLSchemes contains both `mahjaroundtown` and the Google reversed client ID.
- On iPhone, tap Continue with Google, choose an account, and verify login completes and returns to Mahj.
- If Google account selection succeeds but the app shows `The Google account could not be verified for Mahj`, verify the Web client ID in this file matches Laravel `GOOGLE_SIGN_IN_CLIENT_ID`.
- If the OAuth screen cannot open or return to the app, verify the iOS bundle identifier, client ID and reversed scheme.
- Do not change Firebase Maps keys or the production Stripe configuration as part of this fix.
