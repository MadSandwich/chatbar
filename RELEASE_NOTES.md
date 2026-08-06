# ChatBar Release Notes

## 2.5.0 (Quick-reply Last Whisper)

- Added a "Reply" button/channel and a "Quick-reply last whisper" keybinding that jumps the chat editbox straight to your most recent whisper partner (received or sent), using Blizzard's own last-tell tracking (`ChatFrameUtil.ReplyTell`/`GetLastTellTarget`, with legacy `ChatFrame_ReplyTell` fallback). Works for both regular and Battle.net whispers automatically.
- No new addon-side tracking of whisper senders was needed or added; the feature relies entirely on stable, always-available Blizzard chat APIs unaffected by the 12.1.0 addon security changes (which are scoped to auras, not chat).
- Added localization for the new feature in all supported languages (enUS, deDE, esES, frFR, ruRU, koKR).

## 2.4.1 (Version Bump)

- Version bump only; no functional changes.

## 2.4.0 (Channel History Cycling)

- Added channel history cycling: ChatBar now remembers the channels you switch to during a session.
- Added two keybindings ("Cycle to previous channel" / "Cycle to next channel") to rotate through recently used channels; cycling wraps around and skips channels that are no longer available.
- Added a setting to enable or disable channel history cycling.
- Centralized channel switching so button clicks and history cycling share the same logic.
- Added localization for the new feature in all supported languages (enUS, deDE, esES, frFR, ruRU, koKR).
- Fixed a settings panel label that could run off-screen with longer localized text.

## 2.2.5 (WoW 12.0.7 Compatibility)

- Added Retail interface compatibility for 12.0.7 in ChatBar.toc.
- Hardened chat opening flow with API fallbacks for channel switching.
- Added safe header refresh fallback for chat edit boxes.
- Improved settings panel opening fallback when modern Settings category APIs are unavailable.
