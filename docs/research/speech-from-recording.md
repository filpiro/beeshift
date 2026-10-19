# Research: dictating a month from a recording instead of a live session

Resolves [#8](https://github.com/filpiro/beeshift/issues/8). Researched 2026-10-20.
Follows [#2](https://github.com/filpiro/beeshift/issues/2) (`docs/research/speech-to-text.md` on branch
`research/speech-to-text`) and the device test [#6](https://github.com/filpiro/beeshift/issues/6).

Problem from #6: live Android recognition (`speech_to_text` 7.5.0, `it_IT`, Pixel 7) ends the session
after ~1-3 s of silence, and the recognizer itself collapses repeated words (`secondo secondo` becomes
`secondo`). Question: can Beeshift record the dictation first (hold/lock, no silence cut-off) and then
transcribe the recording?

Each claim is tagged:

- **Fact (source)**: read in official docs, package source or the pricing page.
- **Reported**: stated in an issue or by a user. Not verified here.
- **Inferred**: my reasoning from the facts. No document says it.
- **Test on device**: no document settles it.

## Sources

| Id | Source |
|---|---|
| S1 | Android `RecognizerIntent` reference: <https://developer.android.com/reference/android/speech/RecognizerIntent> |
| S2 | Android `RecognitionListener` reference: <https://developer.android.com/reference/android/speech/RecognitionListener> |
| S3 | `speech_to_text` 7.5.0 and 7.6.0-beta.4 archives (Kotlin plugin + Dart lib): <https://pub.dev/api/archives/speech_to_text-7.5.0.tar.gz>, <https://pub.dev/api/archives/speech_to_text-7.6.0-beta.4.tar.gz> |
| S4 | `stts` 1.3.4 archive (<https://pub.dev/api/archives/stts-1.3.4.tar.gz>) and issue [llfbandit/stts#10](https://github.com/llfbandit/stts/issues/10) "Add support for STT recognizing from an audio file" |
| S5 | whisper.cpp README (memory table, Android example): <https://github.com/ggml-org/whisper.cpp>, <https://github.com/ggml-org/whisper.cpp/tree/master/examples/whisper.android> |
| S6 | OpenAI Whisper README (model table) <https://github.com/openai/whisper> and paper "Robust Speech Recognition via Large-Scale Weak Supervision", Appendix D.2 (MLS and FLEURS WER per language): <https://arxiv.org/abs/2212.04356> |
| S7 | pub.dev API for `whisper_ggml`, `whisper_flutter_new`, `whisper_ggml_plus`, `whisper_cpp_flutter_plus`, `whisper_kit`, `flutter_whisper_kit`, `record`, `stts` (<https://pub.dev/api/packages/NAME>), and the `whisper_ggml` 2.8.1 archive (README, CHANGELOG, `android/build.gradle`, `pubspec.yaml`, `lib/`) |
| S8 | whisper.cpp issue [#1637](https://github.com/ggml-org/whisper.cpp/issues/1637) (Pixel 7 timing, Dec 2023) |
| S9 | Google Cloud Speech-to-Text pricing: <https://cloud.google.com/speech-to-text/pricing> |
| S10 | Google Cloud Speech-to-Text supported languages: <https://cloud.google.com/speech-to-text/docs/speech-to-text-supported-languages> |
| S11 | Google Cloud Speech-to-Text quotas and limits: <https://cloud.google.com/speech-to-text/docs/quotas>; model adaptation: <https://cloud.google.com/speech-to-text/v2/docs/adaptation-model>; batch recognize: <https://cloud.google.com/speech-to-text/v2/docs/batch-recognize> |
| S12 | This repo on `origin/main`: `pubspec.yaml` (no speech, recording or HTTP package yet), `android/app/build.gradle.kts` (`minSdk = flutter.minSdkVersion`) |

## Summary

| | Route 1: Android recognizer fed a recording | Route 2: on-device Whisper | Route 3: Google Cloud STT |
|---|---|---|---|
| Exists as believed | Yes, `EXTRA_AUDIO_SOURCE`, API 33+ (S1) | Yes, several plugins (S7) | Yes (S9-S11) |
| Italian | Same recognizer as today | `small` FLEURS WER 9.8 %, `base` 17.9 % (S6) | `it-IT`, incl. `eu` region, with model adaptation (S10) |
| Offline | Same as today (network by default) | Fully offline | Network only |
| App size | ~0 | Model 142-466 MiB + native libs + bundled FFmpeg (S5, S7) | HTTP client only |
| Latency | Unknown (Test on device) | Unknown on a phone; likely seconds to tens of seconds for `small` (Inferred) | One request; ~1 round trip after upload (Inferred) |
| Money | Free | Free | ~USD 0.016 / min, 1 s rounding (S9) |
| Privacy | Audio goes to Google's recognizer, as today | Audio stays on the phone | Audio goes to Google Cloud |
| Flutter effort | Custom Kotlin platform channel (no plugin supports it) | Add plugin + `record`; model download/caching UX | `record` + HTTP + credentials (needs a backend or key proxy) |
| Repeated words survive? | Probably not (same model, Inferred) | Unknown, plausible (Test on device) | Unknown (Test on device) |

## Route 1: Android `SpeechRecognizer` fed from a recording

### Does `EXTRA_AUDIO_SOURCE` exist as believed?

- **Fact (S1):** `EXTRA_AUDIO_SOURCE`, "Added in API level 33": "Optional ParcelFileDescriptor pointing to an
  already opened audio source for the recognizer to use. The caller of the recognizer is responsible for
  closing the audio. If this extra is not set or the recognizer does not support this feature, the
  recognizer will open the mic for audio and close it when the recognition is finished."
- **Fact (S1):** companion extras (all API 33): `EXTRA_AUDIO_SOURCE_CHANNEL_COUNT` (default 1),
  `EXTRA_AUDIO_SOURCE_ENCODING` (default `AudioFormat.ENCODING_PCM_16BIT`),
  `EXTRA_AUDIO_SOURCE_SAMPLING_RATE` (default 16000). So the input is raw PCM, not a WAV/M4A container.
- **Fact (S1):** `EXTRA_AUDIO_INJECT_SOURCE` (API 31, a URI to an audio resource) is deprecated in API 33,
  "Replaced with EXTRA_AUDIO_SOURCE".
- **Fact (S1):** there is no API to ask whether the recognizer supports the feature. An unsupported
  recognizer silently falls back to the **mic**. The app must detect that itself.

### Does the silence endpointer still apply?

- **Fact (S1, `EXTRA_AUDIO_SOURCE`):** "This can also be used as the string value for
  `EXTRA_SEGMENTED_SESSION` to enable segmented session mode. The audio must be passed in using this extra.
  The recognition session will end when and only when the audio is closed."
- **Fact (S1, `EXTRA_SEGMENTED_SESSION`, API 33):** results come "in segments via
  `RecognitionListener.onSegmentResults(Bundle)`" and the session ends with `onEndOfSegmentedSession()`.
  "Depending on the recognizer implementation, this value may have no effect."
- **Fact (S2):** `onSegmentResults` and `onEndOfSegmentedSession` are API 33 listener methods.
- **Inferred:** with `EXTRA_SEGMENTED_SESSION = EXTRA_AUDIO_SOURCE`, silence does not end the session by
  contract; the app ends it by closing the pipe. Without segmented mode the docs promise nothing about
  silence. Whether Google's recognizer honours either: **Test on device.**
- **Reported (S4, stts#10, 2026-06-23):** a contributor has file-fed recognition "working pretty solid for
  Android" in an unreleased branch. No device, recognizer or language given. A second user (2026-10-07)
  runs a private package that feeds `record` output into the recognizer (pipe-based on Android 13+).

### Reachable from `speech_to_text`?

- **Fact (S3):** neither 7.5.0 nor 7.6.0-beta.4 references `EXTRA_AUDIO_SOURCE`,
  `EXTRA_SEGMENTED_SESSION` or `ParcelFileDescriptor`. The beta only adds `EXTRA_BIASING_STRINGS`.
- **Fact (S4):** `stts` 1.3.4 does not either (it sets `EXTRA_BIASING_STRINGS` only); stts#10 is open.
- So it needs a **custom platform channel** (Kotlin): record PCM 16 kHz mono (e.g. with `record`), open
  `ParcelFileDescriptor.createPipe()`, start `SpeechRecognizer` with the extras above, write the PCM into the
  pipe, close it, collect `onSegmentResults`/`onResults`. Roughly one Kotlin class plus a method channel.
- **Fact (S12):** `minSdk = flutter.minSdkVersion` (below 33), so older phones need the live path as a
  fallback.

### Repeated words

- **Fact (#6):** partials showed `primo primo secondo secondo`, then the recognizer revised to
  `primo primo secondo`. The collapse is inside the recognizer.
- **Inferred:** feeding the same recognizer from a pipe changes the audio source, not the model. Expect
  the same collapse. This route fixes the silence cut-off at best, not the repeat-dropping.
- **Test on device:** feed the #6 recording through the pipe and compare.

### Other properties

- Italian, network, privacy, money: same as today's live path (Google recognizer; audio goes to Google
  unless on-device is used). App size: ~0.
- Latency: unknown. Whether PCM can be written faster than real time is not documented. **Test on device.**

## Route 2: on-device Whisper (whisper.cpp)

### Model size for usable Italian

- **Fact (S6, paper Appendix D.2):** Italian WER by model size:

  | Model | Params | FLEURS it WER | MLS it WER |
  |---|---|---|---|
  | tiny | 39 M | 29.8 % | 41.7 % |
  | base | 74 M | 17.9 % | 31.1 % |
  | small | 244 M | 9.8 % | 21.4 % |
  | medium | 769 M | 5.2 % | 16.0 % |
  | large-v2 | 1550 M | 4.0 % | 13.8 % |

- **Fact (S5):** whisper.cpp disk / memory: tiny 75 MiB / ~273 MB, base 142 MiB / ~388 MB,
  small 466 MiB / ~852 MB, medium 1.5 GiB / ~2.1 GB. Integer quantization (e.g. `q5_0`) shrinks these.
- **Fact (S5, Android example README):** "I recommend the tiny or base models for running on an Android device."
- **Inferred:** WER on read sentences overstates the difficulty of Beeshift's closed vocabulary
  (~8 words). `base` (or quantized `small`) is the likely floor; `tiny` is too weak for Italian.
  An initial prompt listing the vocabulary should help (see below). **Test on device.**

### Speed on a mid-range phone

- **Reported (S8, Dec 2023):** Pixel 7, whisper.cpp Android demo, `base`, 11 s JFK clip: "Done (30141 ms)".
  Old whisper.cpp, build type unknown (the demo README insists on a release build).
- **Fact (S7, `whisper_ggml` README):** "an 11-second clip transcribes in ~0.4 s with the base model on an
  Apple Silicon Mac". Desktop only.
- No first-party phone benchmark found. **Test on device:** a 30-60 s month with `base` and `small`
  (quantized) on the Pixel 7, release build. Expect seconds for `base`; `small` may take tens of seconds
  (Inferred).

### Flutter integration

- **Fact (S7):** candidates on pub.dev (2026-10-20):

  | Package | Latest | Platforms | Notes |
  |---|---|---|---|
  | `whisper_ggml` | 2.8.1 (2026-10-14) | Android, iOS, macOS, Win, Linux | Most active, 8.5k downloads/30 d |
  | `whisper_ggml_plus` | 1.5.2 (2026-04-01) | same | Fork, large-v3-turbo support |
  | `whisper_cpp_flutter_plus` | 0.5.1 (2026-10-06) | Android, iOS | Streaming + VAD |
  | `whisper_flutter_new` | 1.0.1 (2024-06-12) | Android, iOS, macOS | Stale |
  | `whisper_kit` | 0.3.1 (2026-05-07) | Android, iOS, macOS | Small |
  | `flutter_whisper_kit` | 0.3.0 | iOS, macOS only | Not for Android |

- **Fact (S7, `whisper_ggml` 2.8.1):** Android API 24+; whisper.cpp v1.9.1; file transcription in one call
  (`audioPath`); `initialPrompt` exposed ("vocabulary biasing"); models "download once and are cached, or
  ship them in your app's assets"; non-WAV input converted with bundled FFmpeg
  (`ffmpeg_kit_flutter_new_min`); input from `record` as 16 kHz mono WAV works directly.
  `android/build.gradle` builds four ABIs (`armeabi-v7a`, `x86_64`, `arm64-v8a`, `x86`).
- **Inferred:** APK grows by the native libs plus FFmpeg-kit for each ABI, unless split per ABI. Model is
  better downloaded on first use than bundled (142-466 MiB). That needs a download/progress/retry UX.

### Other properties

- Offline: fully. Privacy: audio never leaves the phone. Money: free. Italian: supported (one of 99).
- Repeated words: Whisper decodes a whole 30 s window as text; no source says it collapses repeats. Its
  known failure mode is the opposite (looping/hallucinated repeats on silence). **Test on device** with
  the #6 month.

## Route 3: Google Cloud Speech-to-Text

### Italian

- **Fact (S10):** `it-IT` is supported in V2 in many regions, including `eu` and `europe-west4`. In `eu`:
  `chirp_3` (punctuation, diarization, model adaptation), `long`, `short` (model adaptation, word-level
  confidence, spoken punctuation). `chirp_2` (model adaptation) in `europe-west4`.

### Pricing

- **Fact (S9):** V2 standard recognition USD 0.016 / min for the first 500,000 min per month per account.
  Standard models include `default`, `latest_short`, `latest_long`, `chirp` ("Speech-to-Text V2 only").
  "Each request is rounded up to the nearest increment of 1 seconds."
- **Fact (S9):** V2 dynamic batch USD 0.003 / min. **Fact (S11):** batch takes audio only as a Cloud
  Storage URI, so it suits offline jobs, not an interactive editor.
- **Fact (S9):** V1: first 60 min / month free, then USD 0.016 / min with data logging, USD 0.024 / min
  without.
- **Inferred:** a 30-60 s month costs USD 0.008-0.016. Whether `chirp_3` is billed as "Standard" is not
  stated on the page.

### Limits and phrase hints

- **Fact (S11):** synchronous `Recognize`: "limited to 10 MB or 1 minute of audio duration". A long month
  dictation with pauses can exceed 1 minute; then streaming (5 min max, real-time pace) or batch is needed.
- **Fact (S11, adaptation):** phrase sets and custom classes bias recognition; "By default model adaptation
  provides a relatively small effect, especially for one-word phrases"; `boost` increases it. This fits the
  Shift vocabulary (`primo`, `secondo`, `notte`, `smonto`, `riposo`, `ferie`).

### Other properties

- Network only. Privacy: audio goes to Google Cloud (the `eu` multi-region is listed in S10; that it keeps all processing in the EU is Inferred
  location list). A privacy note in the app would be needed.
- **Inferred:** the app must not ship a service-account key. It needs a small backend or proxy that holds
  credentials, which Beeshift does not have today (S12). This is the main integration cost.
- Repeated words: no source. **Test** with the #6 recording (the API console accepts uploads).

## Recommendation

1. **Record first in every route.** Recording with `record` (16 kHz mono PCM/WAV) removes the silence
   cut-off and gives a file to retry on. That part is cheap and shared.
2. **Run one cheap test before choosing:** transcribe the #6 month recording with whisper.cpp `base` and
   `small` (desktop CLI is fine for accuracy; then the Pixel 7 for speed), and with Google Cloud `chirp_3`
  `eu` plus a phrase set. Count whether `secondo secondo` survives.
3. **Expected pick: on-device Whisper (`whisper_ggml`, `base` or quantized `small`, model downloaded on
  first use, `initialPrompt` with the vocabulary).** It is offline, free, private, and is the only route
  that changes the model, so it can fix repeat-dropping. Cost: ~150-500 MB download and a wait of
  seconds after the user stops.
4. **Route 1 is not worth it on its own:** custom Kotlin, API 33+ only, silent mic fallback, and the same
  model that collapses repeats. Keep it only if the Whisper test fails and Google Cloud is ruled out.
5. **Google Cloud is the fallback** if Whisper is too slow or inaccurate on the phone: best Italian and
  phrase boosting, trivial cost, but it needs network, a credential proxy and a privacy note.

## Test checklist

1. Whisper `base`, `small`, `small-q5`: #6 month recording, with and without `initialPrompt`. Word count,
   repeats kept, time on Pixel 7 (release build).
2. Google Cloud V2 `chirp_3` `eu` with and without a boosted phrase set: same recording.
3. Optional (Route 1): Kotlin probe with `EXTRA_AUDIO_SOURCE` + `EXTRA_SEGMENTED_SESSION`. Does the Google
   recognizer read the pipe or open the mic? Does a 3 s silence end the session? Are repeats kept?
