# Research: `speech_to_text` on Android for Italian monthly dictation

Resolves [#2](https://github.com/filpiro/beeshift/issues/2). Researched 2026-10-19/20.

Scope: what the `speech_to_text` Flutter plugin does on Beeshift's Android setup, so the
Month Editor voice action rests on facts. Each claim is tagged:

- **Fact (source)**: read in the plugin source, its changelog/README, or the Android API reference.
- **Reported**: stated by the maintainer or users in the plugin's GitHub issues. Not verified here.
- **Test on device**: depends on the device's recognizer (usually Google's). No document settles it.

## Sources

| Id | Source |
|---|---|
| S1 | pub.dev API, `speech_to_text` versions and pubspecs: <https://pub.dev/api/packages/speech_to_text> |
| S2 | `speech_to_text` 7.5.0 package archive: `CHANGELOG.md`, `README.md`, `lib/speech_to_text.dart`, `android/src/main/kotlin/com/csdcorp/speech_to_text/SpeechToTextPlugin.kt`, `android/src/main/AndroidManifest.xml`, `android/build.gradle` (<https://pub.dev/api/archives/speech_to_text-7.5.0.tar.gz>) |
| S3 | `speech_to_text_platform_interface` 2.4.0 archive, `lib/method_channel_speech_to_text.dart`, `lib/speech_to_text_platform_interface.dart` |
| S4 | `speech_to_text` 7.6.0-beta.4 archive, `CHANGELOG.md` |
| S5 | Android `RecognizerIntent` reference: <https://developer.android.com/reference/android/speech/RecognizerIntent> |
| S6 | Android `SpeechRecognizer` reference: <https://developer.android.com/reference/android/speech/SpeechRecognizer> |
| S7 | Plugin issues: [#554](https://github.com/csdcorp/speech_to_text/issues/554) (Android listen time), [#253](https://github.com/csdcorp/speech_to_text/issues/253) (restart for continuous), [#661](https://github.com/csdcorp/speech_to_text/issues/661) (auto-restart, beep), [#462](https://github.com/csdcorp/speech_to_text/issues/462) (numbers), [#505](https://github.com/csdcorp/speech_to_text/issues/505) (locales never returns), [#349](https://github.com/csdcorp/speech_to_text/issues/349) (offline), [#683](https://github.com/csdcorp/speech_to_text/issues/683) / PR [#684](https://github.com/csdcorp/speech_to_text/pull/684) (pauseFor/listenFor timer bug) |
| S8 | This repo: `pubspec.yaml`, `pubspec.lock`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`; `pws -c flutter --version` |

## 1. Version compatible with the repo SDK

- **Fact (S8):** the repo declares `sdk: ^3.10.7`. The installed toolchain is Flutter 3.47.6 / Dart 3.13.5. `pubspec.lock` already requires `dart >=3.13.0`, `flutter >=3.47.0`.
- **Fact (S1):** latest stable is **7.5.0** (2026-09-14), requiring `sdk: ^3.12.0`, `flutter: >=3.44.0`. 7.4.0 requires `sdk >=3.3.0`, `flutter >=3.10.0`. Betas `7.6.0-beta.1..4` (Sept 2026) keep 7.5.0's constraints.
- **Fact (S2):** 7.5.0 changes only the SDK floor and moves to built-in Kotlin. Android plugin `minSdkVersion 21`, `compileSdk = flutter.compileSdkVersion`.
- pub resolves against the installed SDK, so 7.5.0 resolves today. If the repo ever wants to support Dart 3.10/3.11 again, bump `environment.sdk` to `^3.12.0` alongside, or 7.4.0 would be picked.

**Recommendation:** `speech_to_text: ^7.5.0`. Do not use the 7.6.0 betas in v0. Two beta features are worth a later look (S4):
`contextualPhrases` (maps to `RecognizerIntent.EXTRA_BIASING_STRINGS` on Android 13+, could bias toward "smonto", "riposo"),
and `cancel()` recreating the recognizer so an immediate `listen()` no longer fails with `error_client`.

## 2. Requesting `it_IT` and detecting availability

How the locale is sent:

- **Fact (S2, Kotlin `onMethodCall "listen"`):** `localeId` defaults to the device default tag, `_` is replaced by `-` (`it_IT` becomes `it-IT`).
- **Fact (S2, `setupRecognizerIntent`):** `EXTRA_LANGUAGE` is put on the intent **only if** the tag differs from `Locale.getDefault().toLanguageTag()`. On an Italian phone nothing is sent and the recognizer uses its default.
- **Fact (S5):** `EXTRA_LANGUAGE` is "Optional IETF language tag (as defined by BCP 47)".
- So call `listen(listenOptions: SpeechListenOptions(localeId: 'it_IT', ...))` always.

How availability can be detected:

- **Fact (S2, Kotlin `locales`):**
  - API 33+ with mic permission and `isOnDeviceRecognitionAvailable`: builds an on-device recognizer and returns `RecognitionSupport.supportedOnDeviceLanguages`.
  - API < 33 (or no permission): sends the `ACTION_GET_LANGUAGE_DETAILS` ordered broadcast (falls back to `com.google.android.googlequicksearchbox`) and returns `EXTRA_SUPPORTED_LANGUAGES`.
  - The device default locale is always the first entry, then the reported languages.
- **Fact (S2, Dart doc on `locales()`):** "Being on this list does not guarantee that the device will be able to recognize the locale"; on Android "there is no way to get the list of languages supported by the online recognizer".
- **Fact (S2, by reading the code):** on API 33+ with permission but **no** on-device recognition, the `if` has no `else`, so the method channel never answers. The same happens if `checkRecognitionSupport` calls `onError` (it only logs). The `locales()` Future then never completes.
- **Reported (S7 #505, open):** `locales()` never returns on a real Android 13 device.

What happens when Italian is not available:

- **Fact (S6):** API 31+ defines `ERROR_LANGUAGE_NOT_SUPPORTED` (12, "Requested language is not available to be used with the current recognizer") and `ERROR_LANGUAGE_UNAVAILABLE` (13, "supported, but not available currently (e.g. not downloaded yet)").
- **Fact (S2):** the plugin maps them to `error_language_not_supported` / `error_language_unavailable` in `onError`.
- **Test on device:** whether Google's online recognizer raises these for `it-IT` or silently recognizes in another language. With network on, Italian is a mainstream language for Google's service; risk is low but unverified.

**Recommendation:** do not gate the mic on `locales()`. Always pass `it_IT`, then handle `error_language_*` as "Italian recognition not available". If `locales()` is used at all (for example in a debug screen), wrap it in `.timeout(...)`.

## 3. Session length: pause timeout, max duration, `listenFor` / `pauseFor`

Native side (Android):

- **Fact (S2, Dart doc on `listen`):** "There is a time limit on listening imposed by both Android and iOS ... Android is usually quite short, especially if there is no active speech event detected, on the order of ten seconds or so."
- **Fact (S2, Dart doc on `pauseFor`):** "On some systems, notably Android, there is a system imposed pause of from one to three seconds that cannot be overridden."
- **Fact (S2, README "Speech recognition stops after a brief pause on Android"):** "In the devices I've used none have had a pause longer than 5 seconds. Unfortunately there appears to be no way to change that behaviour."
- **Reported (S7 #554):** maintainer: "Android has a fixed listen time that cannot be overridden". Setting `listenFor`/`pauseFor` to 1 day did nothing.
- **Fact (S5):** there is **no** documented maximum session duration in `RecognizerIntent` or `SpeechRecognizer`. Ending is the recognizer's endpointer decision.

What `pauseFor` does on Android in 7.5.0:

- **Fact (S2, Kotlin `setupRecognizerIntent`):** since 7.4.0 ("Android now respects the pauseFor value"), `pauseFor` is passed as `EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS`.
- **Fact (S5):** for that extra: "it is extremely rare you'd want to specify this value in an intent. Generally, it should be specified only when it is also used as the value for EXTRA_SEGMENTED_SESSION ... Depending on the recognizer implementation, these values may have no effect."
- **Fact (S2, Kotlin `onEndOfSpeech`):** after the recognizer reports end of speech, the plugin waits `pauseFor` (default **1000 ms**) and then reports `notListening` then `done`/`doneNoResult`. `onBeginningOfSpeech` cancels that timer.

What `listenFor` does:

- **Fact (S2, S3):** `listenFor` is sent over the channel but the Kotlin code never reads it. It is enforced only by a Dart `Timer` that calls `stop()`. It can only shorten a session.
- **Fact (S7 #683, open; confirmed by reading `_setupListenAndPause` / `_stopOnPauseOrListen` in 7.5.0):** the Dart timer stores *remaining* durations and subtracts elapsed time again on each re-arm. With `pauseFor: 15s, listenFor: 120s` a session stopped after ~30-40 s. Fix is PR #684, unmerged as of 2026-10-15.

Will one session survive ~31 words?

- **Not documented anywhere.** It survives only if the speaker never pauses longer than the endpointer's silence window (about 1-3 s, per S2).
- Dictating "primo, primo, riposo, notte, smonto, ferie ..." at a natural pace with commas as short pauses is likely to fit. A user stopping to check a paper rota or think about day 15 will end the session.
- **Test on device:** time a full 31-word month at slow, normal, and "reading from paper" pace. Record where sessions end.

**Recommendation:** do not set `listenFor`. Do not rely on `pauseFor` to extend sessions (no effect is guaranteed and the Dart timer is buggy). Treat "session ended before 28-31 words" as a normal outcome, not an error.

## 4. Chaining sessions ("keep talking")

- **Fact (S2, README "Continuous speech recognition"):** "the plugin is designed for short intermittent use ... There is not yet a way to achieve this goal using the Android or iOS speech recognition capabilities."
- **Reported (S7 #253, #661):** maintainer: "Android speech is not designed to be used for continuous recognition." Users restart `listen()` on `done` / error and concatenate text, and report it works.
- **Fact (S2, Kotlin `startListening`):** `listen` returns `false` (session not started) if the native side still thinks it is listening. The native flag clears on `notListening`, which comes after the `onEndOfSpeech` + `pauseFor` timer or on `onError`.
- **Fact (S2):** `stop()` keeps the recognizer for reuse (except on API 29, where it is destroyed). Each `listen()` reuses it.
- **Fact (S4):** in 7.5.0, `listen()` right after `cancel()` can be rejected with `error_client`. Fixed only in 7.6.0-beta.4.
- **Fact (S2, README "Android beeps"):** Android plays a start/stop sound and "there is no supported way to disable it". **Reported (S7 #661):** Android 15 beeps on every `listen()`.

So chaining is possible, but each session is separate:

- each one starts with a beep and a short gap where speech is lost;
- the app must join the text itself;
- sessions should be started by the user (tap the mic again), not auto-restarted.

**Recommendation for "partial fill + keep talking":** start the next session from the `done` status (never from `cancel()`), only on a user tap. Append the new final result's words after the days already filled. This matches the planned approach. Auto-restart without a tap is fragile (beeps, missed words, OEM variance) and close to the "always-on listening" that v0 rules out.

## 5. What the recognizer emits for the vocabulary

What the plugin passes through:

- **Fact (S2, `updateResults`):** the plugin returns the recognizer's strings unchanged. It sends up to 10 alternates (`EXTRA_MAX_RESULTS = 10`) with confidence or `-1`, as `partial` or `final` results.
- **Fact (S2, `setupRecognizerIntent`):** the plugin always sets `LANGUAGE_MODEL_FREE_FORM`, unless `ListenMode.search` is chosen (then `WEB_SEARCH`). `dictation` / `confirmation` / `deviceDefault` all map to free form on Android.

Formatting (punctuation, casing):

- **Fact (S2):** the plugin never sets `EXTRA_ENABLE_FORMATTING`.
- **Fact (S5):** `EXTRA_ENABLE_FORMATTING` (API 33) "Optional string to enable text formatting (e.g. unspoken punctuation ..., capitalization, etc.)". So formatting is opt-in at API level, but "Depending on the recognizer implementation" the recognizer may still format.

Digits vs words:

- **Reported (S7 #462):** with English, spoken numbers come back as digits ("one thirty" becomes "1:30"). Maintainer: "The speech frameworks don't provide that level of control"; alternates also had digits.
- Expect "sette" and "tre" to arrive as `7` and `3` at least sometimes, possibly joined ("7 3", "73") when said quickly. **Test on device.**

Letters vs letter names: no source. "erre" may arrive as `R`, `r`, `erre`, `Erre`, or a homophone. **Test on device.**

Punctuation and casing: no source for Italian. Expect possibly a capitalized first word and possibly commas when spoken with pauses. **Test on device.**

**Recommendation:** the parser should tokenize on whitespace and punctuation, lowercase, and accept digits, letters and letter names. `data/voice_monthly_shift_entry_v0_spec.md` already requires this. Also check what a run like "sette sette" becomes (a merged "77" would be an unknown token under strict rules). Prefer the first alternate. Using lower alternates is optional and not needed for v0.

## 6. Android manifest permissions and queries

- **Fact (S2):** the plugin's own `AndroidManifest.xml` is **empty**, so nothing is merged in. The app must declare what it needs.
- **Fact (S2, README "Android"):** it lists `RECORD_AUDIO`, `INTERNET`, `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`. For target SDK 30+, add a `<queries>` intent for `android.speech.RecognitionService`.
- **Fact (S2, Kotlin `initializeIfPermitted`):** `initialize()` requests `RECORD_AUDIO` **and** `BLUETOOTH_CONNECT`, unless `SpeechToText.androidNoBluetooth` is passed in `options`. Bluetooth is only used to route a paired headset's mic.
- **Fact (S8):** Beeshift already has `INTERNET` and a `<queries>` block (for `PROCESS_TEXT`). It has no `RECORD_AUDIO`. `targetSdk = flutter.targetSdkVersion` (well above 30).

Minimal additions to `android/app/src/main/AndroidManifest.xml` for v0, with `androidNoBluetooth` passed to `initialize`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<!-- INTERNET is already declared -->

<queries>
    <!-- existing PROCESS_TEXT intent stays -->
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

```dart
await speech.initialize(
  onError: ..., onStatus: ...,
  options: [SpeechToText.androidNoBluetooth],
);
```

Without `androidNoBluetooth`, also declare the three Bluetooth permissions. The user then gets a "Nearby devices" prompt next to the mic prompt.

## 7. Offline behaviour, errors, and status

Offline:

- **Fact (S2, S5):** `SpeechListenOptions.onDevice: true` uses `createOnDeviceSpeechRecognizer` on API 31+ when `isOnDeviceRecognitionAvailable`, otherwise it silently falls back to the default recognizer. It also sets `EXTRA_PREFER_OFFLINE`.
- **Fact (S5):** for `EXTRA_PREFER_OFFLINE`: "Depending on the recognizer implementation, these values may have no effect."
- **Reported (S7 #349):** maintainer: "Without an Internet connection only on device processing will work as the default speech processing on Android uses the server. On device mode only works on some modern devices." A user had it fail in airplane mode both ways.
- **Test on device:** airplane mode with default options, and with `onDevice: true` and the Italian offline pack installed. Expected errors: `error_network`, `error_language_unavailable`, or `error_server_disconnected`.
- v0 already rules out guaranteed offline. Treat any network error as "riprova con la connessione".

Status callbacks:

- **Fact (S2, `initialize` doc and `_onNotifyStatus`):** `onStatus` receives `listening`, `notListening`, `done`. The native `doneNoResult` is mapped to `done`.
- **Fact (S2):** results arrive through the `listen(onResult:)` callback (`finalResult` flag). `finalTimeout` (default 2 s) promotes the last partial to final if no final arrives after `stop()`.

Errors:

- **Fact (S2, Kotlin `onError` / `sendError`):** every Android error reaches `onError` as `SpeechRecognitionError(errorMsg, permanent: true)`. The messages are:

| Android code (S6) | `errorMsg` |
|---|---|
| `ERROR_AUDIO` 3 | `error_audio_error` |
| `ERROR_CLIENT` 5 | `error_client` |
| `ERROR_INSUFFICIENT_PERMISSIONS` 9 | `error_permission` |
| `ERROR_NETWORK` 2 | `error_network` |
| `ERROR_NETWORK_TIMEOUT` 1 | `error_network_timeout` |
| `ERROR_NO_MATCH` 7 | `error_no_match` |
| `ERROR_RECOGNIZER_BUSY` 8 | `error_busy` |
| `ERROR_SERVER` 4 | `error_server` |
| `ERROR_SPEECH_TIMEOUT` 6 | `error_speech_timeout` |
| `ERROR_LANGUAGE_NOT_SUPPORTED` 12 (API 31) | `error_language_not_supported` |
| `ERROR_LANGUAGE_UNAVAILABLE` 13 (API 31) | `error_language_unavailable` |
| `ERROR_SERVER_DISCONNECTED` 11 (API 31) | `error_server_disconnected` |
| `ERROR_TOO_MANY_REQUESTS` 10 (API 31) | `error_too_many_requests` |
| other | `error_unknown (<code>)` |

- **Fact (S2):** `ERROR_NO_MATCH` is rewritten to `error_speech_timeout` when the max RMS stayed below 9 (nothing loud was heard).
- **Fact (S2):** `onError` is suppressed in Dart when the user already called `stop()`/`cancel()` and the session is not listening.

Permission denied:

- **Fact (S2):** permission denied is **not** an error callback. `initialize()` returns `false` (no permission), and `isAvailable` stays `false`.
- **Fact (S2, `hasPermission` doc):** `hasPermission` checks without prompting. "Applications cannot ask for permission again if the user has denied them permission in the past"; the UI must point to system settings.
- **Fact (S2, `initialize` doc):** `initialize()` caches success, so `onError`/`onStatus` cannot be replaced later. Keep one `SpeechToText` instance per app (e.g. inside the speech service).

Recognizer missing:

- **Fact (S2):** `initialize()` throws a `PlatformException` with code `recognizerNotAvailable` when neither `isRecognitionAvailable` nor (API 31+) `isOnDeviceRecognitionAvailable` is true. Wrap `initialize()` in try/catch.
- **Test on device:** on the emulator, whether a recognition service exists depends on the system image (Google APIs/Play images include the Google app).

## Impact on the planned "partial fill + keep talking"

- **Supports it.** Android cannot promise one session for 28-31 words. Any pause over ~1-3 s ends it, and the plugin cannot extend it. So "session ended with fewer words than days" is the *common* case, not a corner case. Partial fill plus a second tap that appends is the right shape.
- **Constraint:** chain on the `done` status after a user tap. Never `cancel()` then `listen()` (7.5.0 `error_client`). Expect a beep and a short dead gap at each restart.
- **Constraint:** append only `finalResult` text per session. Partials are useful for live display only.
- **Constraint:** do not use `listenFor`/`pauseFor` to try to keep one long session. There is no guaranteed effect on Android, and the Dart timer bug #683 shortens sessions.
- **Watch:** digits and possible merged numbers ("77") may arrive. The strict unknown-word rule will reject them unless the parser handles digit runs. Decide after the device test.

## Device test checklist (one session on the active emulator plus one real phone)

1. Phone in Italian vs English system language with `localeId: 'it_IT'`: does Italian recognition work in both?
2. Dictate a 31-word month at normal pace without pausing: where does the session end? Is the final transcript complete?
3. The same with a 3 s pause after day 10: does the session end, and what final result arrives?
4. Tap again after `done`: time to `listening`, beep, any `error_busy`/`error_client`.
5. Raw output for "primo sette secondo tre riposo erre notte enne smonto esse ferie effe": digits? letters? casing? punctuation? merged numbers for "sette sette"?
6. Airplane mode: default and `onDevice: true`: which error?
7. Deny mic permission, then "don't ask again": `initialize()` result and `hasPermission`.
8. `locales()` on API 33+: does it return, and does it include `it_IT`?
