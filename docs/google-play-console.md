# Google Play Console pack — Mahj Around Town

Use this when filling **Google Play Console** for Android package `fun.aroundtown.mahjaroundtown` (app version `1.0.0`, version code `1`).

The launcher name in the app is **Mahj Around Town**. Keep the store name the same.

Icon, feature graphic, and screenshots are **not** included. Specs are at the bottom so those can be added when the assets are ready.

Confirm two things before you submit:

1. **Privacy policy URL.** Play rejects the app without a public `https://` privacy policy page. The policy currently lives inside the app only. A draft you can publish is in [Privacy policy draft](#privacy-policy-draft).
2. **Account deletion URL.** The app can delete an account from **Account settings**. Play still asks for a public web link. A short page you can publish is in [Account deletion page](#account-deletion-page).

Replace every `[BRACKET]` before you paste.

| Placeholder | What to put |
| --- | --- |
| `[PRIVACY_POLICY_URL]` | Public privacy policy page |
| `[ACCOUNT_DELETION_URL]` | Public account-deletion page |
| `[SUPPORT_EMAIL]` | Real inbox. In-app preview uses `support@mahj.app`. Use that only if the mailbox exists. |
| `[WEBSITE_URL]` | Public site, or leave blank if you have none. `https://app.aroundtown.fun` is the API host, not a store website. |
| `[REVIEWER_EMAIL]` | Demo account email that can pass login |
| `[REVIEWER_PASSWORD]` | Demo account password |
| `[COUNTRIES]` | Suggested start: United States. Profile fields are city, state, and ZIP. |

---

## 1. Main store listing

**Grow users → Store presence → Main store listing**

### App name (max 30)

```
Mahj Around Town
```

17 characters.

### Short description (max 80)

```
Find, host, and join local mahjong games with players around town.
```

64 characters.

### Full description (max 4000)

```
Mahj Around Town helps you find and host mahjong games with players near you.

Browse matches in a list or on a map, set how far you want to look, and join a table that fits your schedule. Hosts can create a match, choose the place and time, add notes, and invite players. After you join, use match chat or a direct message to coordinate before you meet.

What you can do
• Discover mahjong matches around a place you choose
• Create a match and invite players
• View games on a map and set a search radius
• Chat with players in a match or one to one
• Keep a profile, favorites, and your match history
• Block or report a player from Privacy and Safety
• Get notifications for invitations, messages, and match updates

Mahj Around Town arranges real games. It does not play mahjong for you, take wagers, or supervise the event. You choose where and when to meet.

A subscription unlocks nearby matches, creating and joining games, and player chat. New members can start with a free trial when one is offered. The price, trial length, and renewal terms are shown in the app before you subscribe.

Location is used while you use the app, to show matches near you and to set a match place. You can search for a place instead of using your current location. Mahj Around Town does not track your location in the background.

Mahj Around Town is for adults arranging in-person games. Treat other players with respect. You can block and report players in the app.
```

Do not add a price, a star rating, or “best” or “#1” claims. The live price comes from the server (the screen default is `$19.99/month` after a 30-day trial). Leave the price out of the description so a price change does not make the listing wrong.

---

## 2. Store settings

**Grow users → Store presence → Store settings**

| Field | Answer |
| --- | --- |
| App category | **Lifestyle** |
| Tags | Pick up to 5 that the console actually lists. Prefer tags about events, community, communication, or local activities. |
| Email | `[SUPPORT_EMAIL]` |
| Phone | Optional. Leave blank unless you want a public support number. |
| Website | `[WEBSITE_URL]` or blank |
| External marketing | No, unless you later run Play feature campaigns |

**Lifestyle** matches a local-activities app. **Social** is the other reasonable choice because of profiles and chat. Use one category. Play no longer asks for a second category.

---

## 3. App content questionnaires

Open **Policy → App content** and complete each item. Answers below match the current app.

### Privacy policy

| Question | Answer |
| --- | --- |
| Privacy policy URL | `[PRIVACY_POLICY_URL]` |

### Ads

| Question | Answer |
| --- | --- |
| Does the app contain ads? | **No** |

No ad SDK is in the app.

### Advertising ID

| Question | Answer |
| --- | --- |
| Does your app use an advertising ID? | **No** |

The app does not use the advertising ID for ads or analytics. After you upload the Android App Bundle, open the pre-launch report. If Play says the `AD_ID` permission is in the bundle because of a Google library, change this answer to **Yes**, then choose that it is **not used for advertising**. Do not declare ads if you only had to acknowledge that permission.

### App access

Some features need an account, and core features sit behind the subscription. Reviewers must be able to sign in and see matches, map, create-match, and chat.

| Question | Answer |
| --- | --- |
| Are all features available without special access? | **No**. All or some functionality is restricted. |
| Login required | Yes |

Instructions to paste:

```
This app requires an account. Subscription features (nearby matches, create/join, and chat) must already be active on the demo account.

1. Open the app.
2. Sign in with email and password. Do not use Google sign-in.
3. Email: [REVIEWER_EMAIL]
4. Password: [REVIEWER_PASSWORD]
5. The demo account has an active subscription, so no payment is required.
6. Home shows nearby matches. The map is the map tab. Create match is the + button. Chat is available from a match or the messages icon.
7. Location permission is optional. If prompted, Allow only while using the app, or skip and search for a city instead.
8. Notifications are optional. Reviewers can deny notification permission.
```

Create that demo account on production (`https://app.aroundtown.fun`) before you submit. If the trial is expired, reviewers will hit Stripe checkout and cannot finish review.

Any other login instructions, OTP codes, or 2FA: add them here. Registration uses email OTP; the demo account should already be verified so reviewers are not blocked on a code.

### Content rating

Start the questionnaire. Category of the app inside the rating form: **Social or Communication** if that option is offered. Otherwise **All other app types**.

Answer the content questions as follows.

| Topic | Answer |
| --- | --- |
| Violence | None. No violence, weapons, blood, or graphic scenes. |
| Sexuality | None. No sexual content or nudity. |
| Language | The app does not ship with profanity. Users can type their own chat messages. |
| Controlled substances | None. No references to drugs, alcohol, or tobacco. |
| Crude or scary content | None. |
| Gambling | **No.** The app has no bets, buy-ins, chips, payouts, or simulated casino play. It only helps people schedule a mahjong game. |
| User interaction | **Yes.** Users can chat, send invitations, and see profiles. |
| Shares location with other users | **Yes.** A host’s chosen match place is visible to players on the list and map. The app does not broadcast a live GPS trail of a person. |
| Personal information shared | **Yes.** Name, profile photo, bio, and city-style location can be visible to other players. |
| Digital purchases | **Yes.** Optional subscription. |
| Unrestricted web browsing | **No.** There is no in-app browser for the open web. Checkout can open a Stripe payment page. |
| User-generated content shared publicly or with other users | **Yes.** Profiles, match notes, and chat. |
| Users can block other users | **Yes.** Privacy and Safety, and the player profile. |
| Users can report content or users | **Yes.** |
| Moderation | Reports can be filed in the app. Say that reports are reviewed. Do not claim 24-hour moderation unless that is actually staffed. |
| Online-only interaction, not in person | **No.** The purpose is in-person games. Chat is used to coordinate those games. |

Save the form and **apply the rating certificate** Play generates. Do not edit the rating by hand. For this kind of user-to-user app, the certificate is commonly **Teen** or **Mature 17+**. Either result is acceptable. Keep the target age at 18 and older (next section) even if the certificate says Teen.

### Target audience and content

| Question | Answer |
| --- | --- |
| Target age groups | **18 and over** only. Do not select 13 or under, 14–15, or 16–17. |
| Appeal to children | **No** |
| Designed for children | **No** |
| Families / teacher-approved program | Do not opt in |

The app arranges in-person meetings with other adults and includes chat. It should not be in the Designed for Families program.

### News apps

| Question | Answer |
| --- | --- |
| Is this a news app? | **No** |

### COVID-19 contact tracing and status apps

| Question | Answer |
| --- | --- |
| COVID-19 app | **No** |

### Data safety

Summary answers, then each data type.

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes.** The API is `https://app.aroundtown.fun`. |
| Do you provide a way for users to request that their data be deleted? | **Yes** |
| Deletion method | In the app: **Account settings → Delete account**. Also publish `[ACCOUNT_DELETION_URL]`. |
| Which account deletion link? | `[ACCOUNT_DELETION_URL]` |
| Independent security review | **No**, unless you have completed one |

“Shared” below means shown to other users or sent to a third party that is not only processing data for you. Google’s form says service providers that process data on your behalf (your API host, Firebase Cloud Messaging, Google Sign-In, Google Maps, Stripe) are **not** “sharing.” Follow that when the form asks. Where other players can see the data, mark it **shared**.

| Data type | Collected | Shared | Optional? | Purpose | Notes |
| --- | --- | --- | --- | --- | --- |
| Personal info → Name | Yes | Yes, with other users | Required | App functionality, Account management | Profile name |
| Personal info → Email address | Yes | No | Required | App functionality, Account management | Sign-in, OTP, password reset. Not shown on the public player screen. |
| Personal info → User IDs | Yes | No | Required | App functionality, Account management | Account id |
| Personal info → Phone number | Yes | No | Optional | App functionality, Account management | Profile field. Leave “shared” off unless other players can see the number. |
| Personal info → Address | Yes | Approximate city may be visible | Optional | App functionality, Account management | City, state, ZIP on the profile. Not a street address. |
| Personal info → Other info | Yes | Yes, with other users | Optional | App functionality | Bio |
| Financial info → Purchase history | Yes | No | Optional | App functionality | Subscription status. Card numbers are entered on Stripe, not stored in the app. |
| Financial info → User payment info | Yes, by the payment processor during checkout | No | Optional | App functionality | Only if the form asks about checkout. Mark that you do not retain card numbers. If the console allows “data is processed ephemerally,” use that for card details. |
| Location → Precise location | Yes | No live trail. Match pins are a chosen place, covered as location sharing in the rating form. | Optional | App functionality | While the app is in use, when the user asks for current location. Not collected in the background. |
| Location → Approximate location | Yes | City can be visible on a profile | Optional | App functionality | City / ZIP and distance used for nearby results |
| Photos → Photos | Yes | Yes, with other users | Optional | App functionality | Profile photo chosen from the gallery. Support requests can also attach a photo from the gallery. |
| Photos → Videos | No | No | — | — | The app does not collect video. |
| Messages → Other in-app messages | Yes | Yes, with the people in that chat | Optional | App functionality | Match chat and direct messages |
| App activity → App interactions | Yes | No | Required once they use the app | App functionality, Analytics only if you add analytics later | Matches joined, hosted, favorites, invitations. Do **not** select Advertising. |
| App activity → In-app search history | Yes | No | Optional | App functionality | Place search for matches |
| App activity → Other user-generated content | Yes | Yes, with other users | Optional | App functionality | Match notes, invitations, reports |
| Device or other IDs | Yes | No | Required for push after they allow notifications | App functionality | Firebase Cloud Messaging device token, sent to your server at `/device-tokens` |
| Crash logs / Diagnostics | No | No | — | — | Do not declare crash logs unless you add Crashlytics or similar. |
| Contacts, SMS, calendar, files, audio, web history, health, fitness | No | No | — | — | Not used |
| Installed apps | No | No | — | — | Not used |

For every collected type, when the form asks why it is collected, select **App functionality**. Also select **Account management** for name, email, user id, phone, and address. Do not select Advertising or Marketing.

Data is **not** sold.

Users can **delete the account** in the app. Until that ships on a public URL as well, paste `[ACCOUNT_DELETION_URL]`.

### Government apps

| Question | Answer |
| --- | --- |
| Is this a government app? | **No** |

### Financial features

This form is about banking, loans, crypto, trading, and similar products. It is not the subscription price.

| Question | Answer |
| --- | --- |
| Does your app provide financial features? | **No** |

The subscription is access to app features. It is not a wallet, bank, loan, or money-transfer product.

### Health

If this form appears:

| Question | Answer |
| --- | --- |
| Health app or health data | **No** |

---

## 4. Location, photos, and notifications

These forms often appear **after the first app bundle upload**, because the manifest requests the permissions.

Manifest permissions today:

- `INTERNET`
- `POST_NOTIFICATIONS`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`

There is no camera permission and no background-location permission. Profile and support photos use the system gallery picker.

### Location permissions declaration

| Question | Answer |
| --- | --- |
| Does your app access location in the background? | **No** |
| Foreground location | **Yes** |
| Feature shown on the declaration | Finding nearby mahjong matches and setting a match location |
| Is location required for the app to function? | **No.** Users can search for a place. |
| Video of the feature | Record a short clip if Play asks: open Home, choose current location, allow permission, show nearby matches. |

Play’s location policy also expects a short in-app explanation **before** the system permission dialog, and a disclosure in the privacy policy. The privacy draft below includes that disclosure. If the app still requests location with only the system dialog, add one screen or dialog first that says location is used to find nearby matches and is not used in the background. That is a review item, separate from this listing text.

### Photo and video permissions

| Question | Answer |
| --- | --- |
| Does the app need broad access to all photos? | **No**, if the release bundle does not add `READ_MEDIA_IMAGES` or `READ_EXTERNAL_STORAGE`. The app uses the system picker for one profile photo or one support attachment. |
| If Play still shows a photo-permission form because a library added the permission | Choose infrequent, user-initiated use: set a profile photo, or attach a screenshot to a support request. Do not say the app needs persistent access to the whole gallery. |

### Notifications

No separate “ads notification” declaration. Notifications are for invitations, messages, and match activity. Users can deny `POST_NOTIFICATIONS`.

---

## 5. Pricing, distribution, and the subscription

**Monetize → Products** and **Release → Production → Countries**

| Field | Answer |
| --- | --- |
| Paid or free | **Free** to install |
| Countries | `[COUNTRIES]` |
| Contains ads | No |
| Play in-app products | None today |

The app charges through **Stripe**, not Google Play Billing. The checkout return link is `mahjaroundtown://billing`. Play’s payments policy requires Google Play Billing for digital features used inside the app, including a subscription that unlocks matches and chat. A real-world goods exception does not cover those in-app features.

Before review, either:

- move the subscription to **Google Play Billing**, or
- be ready for a policy rejection on the Stripe checkout

Do not create a Play subscription product until the app actually uses Play Billing. A product that the app never purchases will not satisfy that policy.

Suggested Play product, only after the app is switched:

| Field | Value |
| --- | --- |
| Product id | `mahj_monthly` |
| Name | Monthly |
| Description | Nearby matches, create and join, and player chat |
| Billing period | Monthly |
| Price | Match the live plan. Screen default is `$19.99`. |
| Free trial | 30 days, if the live plan still offers it |
| Grace period | Optional |

---

## 6. Release notes

**Release → Production → Release notes**, locale `en-US`

```
First public release of Mahj Around Town. Find nearby mahjong games, host a match, and chat with players.
```

---

## 7. Graphics to add later

Prepare these when the icon and screenshots are ready. Do not upload store screenshots that show another person’s private chat, a real phone number, or a test password.

| Asset | Spec |
| --- | --- |
| App icon | 512 × 512 PNG, 32-bit, under 1 MB. Matches the in-app icon. |
| Feature graphic | 1024 × 500 JPG or PNG, under 15 MB. App name plus a table or map visual. No tiny text, no device frame required. |
| Phone screenshots | At least 2, up to 8. PNG or JPEG. Short side at least 1080 px, 9:16. Recommended 1080 × 1920. |
| 7-inch and 10-inch tablet | Optional. Upload only if you want tablet listings. The app is phone-first. |
| Promo video | Optional YouTube link. Not required. |

Screenshot order that tells the story:

1. Home, with nearby matches
2. Map with a radius
3. Match details
4. Create match
5. Chat
6. Profile
7. Privacy and Safety (block / report)
8. Subscription screen, if you want buyers to see the trial

Use a demo account and a clean status bar.

---

## 8. Signing

Release builds read `android/key.properties` when that file exists. Play App Signing should be turned **on** (the default for new apps). Upload the **AAB**, not an APK. Keep the upload keystore outside git.

First production release needs a closed test track with enough testers if the account is a new personal developer account. Play enforces that requirement in the console. Organization accounts are often exempt. Follow the banner Play shows on the Production page.

---

## Privacy policy draft

Publish this page at `[PRIVACY_POLICY_URL]`. Update the date and the contact email before you publish. This draft matches the in-app policy dated June 8, 2026, plus the data the Android app actually sends.

```
Privacy Policy
Mahj Around Town
Last updated: June 8, 2026

Mahj Around Town ("we") provides a mobile app that helps adults find, host, and join local mahjong games.

This policy describes how the Android app and its backend handle information. By creating an account or using the app, you agree to this policy. If you do not agree, do not use the app.

Information we collect

Account and profile. Name, email address, password, and account id are required. Phone number, ZIP code, city, state, bio, and profile photo are optional and provided by you. You can sign in with email and password. Google sign-in is also offered. If you use Google sign-in, Google shares the account details needed to create or open your Mahj Around Town account.

Match activity. Matches you create, join, host, or save, invitations, attendance-style stats, and notes you add to a match.

Messages. Text you send in a match chat or a direct chat, and messages you send to support. Support messages can include a photo you choose from your gallery.

Location. If you allow location access, the app reads your device location while the app is in use to show nearby matches and distances. You can instead search for a city or address. When you create a match, the place you pick is stored and shown to other players. We do not collect location in the background.

Photos. A profile photo, and any image you attach to a support request, comes from your gallery through the system picker.

Device and notifications. If you allow notifications, we store a Firebase Cloud Messaging device token so we can deliver invitations, messages, and match updates.

Subscription. If you subscribe, payment card details are entered on Stripe’s checkout page. We store subscription status, such as whether a plan is active. We do not store your full card number.

How we use information

We use information to operate the app, show relevant matches, provide chat and invitations, run your account and subscription, send notifications you allow, respond to support requests, and prevent abuse.

Location is used to show nearby matches and to let you set a match place. You can turn location off in your device settings. You can keep using place search.

Sharing

We do not sell personal information.

Other players can see your name, profile photo, bio, match participation, and the match places you publish. People in a chat can see the messages in that chat. Email and phone are used for your account and are not presented as public profile fields.

We use service providers to run the app, including hosting for https://app.aroundtown.fun, Google Maps and Places, Google sign-in, Firebase Cloud Messaging, and Stripe for subscription checkout. They process information for those features.

We may also share information if required by law, or to protect users and the service.

Retention

We keep information for as long as your account is active and as needed for safety, legal, and operational reasons. You can delete your account in the app under Account settings. You can also use the account deletion page linked from the store listing.

Your choices

You can update your profile, deny or revoke location and notification permissions in system settings, block users, report users, and delete your account.

Security

We use reasonable technical and organizational safeguards, including encryption in transit over HTTPS. No method of storage or transmission is completely secure.

Children

Mahj Around Town is not for anyone under 18. We do not knowingly collect information from children.

Changes

We may update this policy. The latest version will be posted on this page and in the app. The in-app policy can be opened from the app’s legal screen.

Contact

[SUPPORT_EMAIL]
```

## Account deletion page

Publish at `[ACCOUNT_DELETION_URL]`.

```
Delete your Mahj Around Town account

You can delete your account in the app:

1. Open Mahj Around Town and sign in.
2. Open Settings, then Account settings.
3. Choose Delete account and confirm.

Deletion removes the account and the profile, messages, and match participation tied to it, except for records we must keep for security, fraud prevention, or legal reasons.

If you cannot sign in, email [SUPPORT_EMAIL] from the address on the account and ask for deletion.

Subscriptions billed by Stripe must be canceled so the plan does not renew. Deleting the app account does not by itself cancel a card charge that Stripe has already scheduled. Cancel the subscription in the app before you delete the account, or ask support to confirm it is canceled.
```
