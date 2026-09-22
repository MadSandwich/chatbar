# ChatBar Release Notes

## 3.0.1

- **Fixed doubled checkbox and radio-button labels in the options panel.**
  `UICheckButtonTemplate` / `UIRadioButtonTemplate` already supply a label
  FontString; the panel was creating a second one on top of it. The template's
  own label is now restyled instead of being shadowed.
- **Removed the pre-Settings-API fallbacks** (`InterfaceOptions_AddCategory`,
  `InterfaceOptionsFrame_OpenToCategory`), which no longer exist on supported
  clients.
- Dropped the `L.KEY or "English fallback"` pattern across the options panel --
  the locale table already fills every key from enUS -- and added type
  annotations so the addon checks clean under the Lua language server.

## 3.0.0 (Design Rework)

- **Replaced the texture-file skin system with a code-driven theme engine.** The
  `Skins/` folder and `Textures.lua` are gone; every surface is now painted with
  `SetColorTexture` / `SetGradient` from theme tokens, so the look is resolution
  independent, hot-swappable, and roughly 200 KB smaller to ship.
- **Two themes**, both built on the same design and selectable at runtime: Flat
  (channel-colored plates, the active one filled in, an accent rule under the
  bar) and Glass (the same design as glass, each plate a gradient lit from above
  under a sheen, with a rim that lifts to the accent when its channel is active).
- **Channel colors are luminance-normalized.** Every plate is the channel's own
  hue rescaled to a fixed perceptual luminance, so the row reads as one family
  instead of inheriting the unevenness of `ChatTypeInfo` -- where SAY is pure
  white and GUILD is nearly black. White labels clear WCAG AA against every
  channel plate in every state. Numbered channels are left uncolored on
  purpose and render as a neutral group.
- **Button shape is square by default**, and the dropdown offers the shapes
  themselves rather than a "follow the theme" entry. Flat is a tab strip and
  fixes its shape, so its control greys out rather than offering a choice that
  would break the design; Glass stays reshapeable between square and round.
  Round buttons are masked, so their edge is drawn as a rim rather than as the
  four pixel-snapped strips a square uses -- the same theme tokens drive both.
- **Two fonts**: the client's own UI face (resolved through a Blizzard font
  object, so it is correct in every language) and a bundled Expressway Free,
  which covers Latin, Latin-1 and the full Cyrillic alphabet. On koKR, zhCN and
  zhTW -- the locales it has no glyphs for -- it falls back to the client face
  rather than rendering empty boxes.
- **New pixel-perfect layer** (`Core/Pixel.lua`): borders are four solid strips
  snapped to the physical pixel grid rather than a NineSlice backdrop, so a 1px
  edge stays exactly one pixel at every resolution and UI scale, and re-snaps on
  `UI_SCALE_CHANGED` / `DISPLAY_SIZE_CHANGED`.
- **Accent color system**: class color by default, plus five presets and a
  custom color picker. The accent marks the active channel and updates live.

- **Active-channel indicator**: the button matching the chat box's current
  channel is highlighted, and clears when the edit box loses focus.
- **Alert notifications** pulse the plate or the label depending on the theme,
  instead of blooming an additive glow over the button.
- **Settings panel rebuilt**: migrated off `UIDropDownMenuTemplate` (deprecated
  since 11.0, with `EasyMenu` removed in the same patch) to `DropdownButton` /
  `WowStyle1DropdownTemplate` and `MenuUtil`, and added a live theme preview
  rendered by the real design engine.
- **Secret Values guard** (12.0): the text-preserving channel switch now checks
  `issecretvalue` before touching the edit box contents, which a whisper edit box
  can return as a protected string.
- Fonts are derived from Blizzard font objects rather than hardcoded paths, so
  the bar follows the client's locale font.
- Saved settings migrate automatically: the Default skin becomes Flat, Round
  becomes Glass with round buttons, and the old Minimal skin becomes Flat --
  which is what Minimal grew into.
- **Channel selection is remembered.** The accent marks whichever channel you
  picked and stays there, surviving both the chat box losing focus and a reload,
  instead of only showing while the input field is open.
- **Background color and opacity are player-controlled.** A color swatch
  (right-click to hand the color back to the theme) tints the bar backdrop and
  the button plates; channel-tinted themes take it as a partial blend so the
  per-channel identity still reads through. The opacity slider applies to the
  bar backdrop *only* -- it lets the world show through behind the bar without
  fading the channel buttons sitting on it. It is disabled on themes that draw
  no bar background.
- **Font selection**: Game default, Narrow, Chat, or System. Choices are named
  through Blizzard font *objects*, never file paths, because Blizzard points each
  object at a different file per locale -- a hardcoded path renders nothing in
  ruRU or koKR.
- **Optically centred labels.** A FontString centres its line box, which reserves
  descender space that uppercase glyphs never use, so geometric centring sat the
  letters visibly high. Labels are now nudged onto their cap height.
- The bar is pinned to the pixel grid rather than anchored straight to the chat
  frame, which sits on fractional coordinates and made small labels render soft.
- Added localization for all new strings (enUS, deDE, esES, frFR, ruRU, koKR).

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
