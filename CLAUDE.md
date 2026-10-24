# ChatBar

WoW addon: a bar of chat-channel buttons above the chat window. One package and one TOC load on Retail (Midnight), WoW: Forever, Mists Classic and Classic Era. Lua 5.1; no libraries, no image files. Detailed design notes live in the code comments; this file is the map.

## Environment

- Client: `D:\BattleNet\World of Warcraft\_retail_` (the only flavor installed here). After a patch, read the build from `D:\BattleNet\World of Warcraft\.build.info`; `/bump-up` turns new builds into `## Interface:` entries.
- `AddOns\ChatBar` is a junction to this repo, so a `/reload` runs the working tree. A `.toc` change or a new file still needs a full client restart.
- Installed in game: !BugGrabber, BugSack, `!Mechanic` and `Mechanic` (junctions to `D:\Projects\Mechanic`). Account folder: `WTF\Account\417236102#1`.
- Release packages leave out every dotfile and the files under `ignore` in `.pkgmeta`. Add any new root-level file that isn't addon code to that list, or it ships.

## Which tool for what

| Need | Use |
| --- | --- |
| API signature, event payload, enum | `wow_api_search` / `wow_api_event_search` / `wow_api_type_search` (MCP `wow`), with `flavor` set when the code must run on Classic too |
| How Blizzard implements something | `wow_ui_grep`, `wow_ui_read_file`. Chat: `Blizzard_ChatFrameBase/Shared/` (`ChatFrameUtil.lua`, `ChatFrameEditBox.lua`) |
| Can a return value be secret? | Mechanic `api-info` (`canBeSecret`) |
| In-game evidence | Mechanic MCP, following the `using-mechanic` skill |
| Debugging | `s-debug` skill; taint: user runs `/console taintLog 1`, reproduces, then read `_retail_\Logs\taint.log` |
| Visual check | Ask the user to press PrtScn, then read the newest `_retail_\Screenshots\WoWScrnShot_*.jpg` |

## Checks after every change

Lua edits:

1. Mechanic `addon-lint` with `{"addon":"ChatBar"}` (luacheck, config in `.luacheckrc`). Expect 0 warnings.
2. `wow_lua_lint` on each changed file. It doesn't know Blizzard's Lua-side functions (`CreateColor`, `CreateFramePool`, `GameTooltip_SetTitle`, `CreateMinimalSliderFormatter`); confirm them with `wow_ui_grep` and pass them in `knownGlobals`.
3. LuaLS: `~/.vscode/extensions/sumneko.lua-3.19.2-win32-x64/server/bin/lua-language-server.exe --check=D:/Projects/chatbar --checklevel=Warning --check_out_path=<scratchpad>/out.json` (config in `.luarc.json`). Expect `[]`.
4. Mechanic `addon-security` and `addon-deprecations`.
5. Locale edits: Mechanic `locale-validate`. Keys must be written `L["KEY"]` in the locale files for it to see them.

TOC edits: `wow_toc_validate`.

In game: `diagnostic-targets`, then `lua-queue` if needed, then ask the user to `/reload` and **wait for their confirmation**, then `addon-output` with `agent_mode: true` and the same target.

Expected noise, not bugs:

- `addon-deprecations` flags the `ChatEdit_*` / `ChatFrame_*` fallbacks in `ChatBar.lua`. Each sits behind a `ChatFrameUtil` check.
- `wow_toc_validate`: backslash paths (Blizzard's own TOCs use them), "bindings.xml is not listed" (the client loads `Bindings.xml` by name), and Interface numbers newer than its own table.
- `locale-validate`: `ADDON_NAME` missing from every translation. It's the colour-coded addon name and is deliberately not translated.

Never report a change as working without saying which checks ran and whether it was verified in game.

## Architecture

Load order is the TOC order, and each file only reads modules loaded before it, except at runtime:

1. `Locales/enUS.lua` creates `ns.L` (missing keys fall back to the key name) and sets the `BINDING_*` globals; `Locales/<locale>.lua` overrides keys for deDE, esES (also esMX), frFR, koKR and ruRU.
2. `Core/Pixel.lua`: the physical-pixel grid, snapping helpers and the four-strip 1px border. Never use `BackdropTemplate` for thin borders.
3. `Core/Theme.lua`: accent and font resolution, colour maths, change notification (`Theme:NotifyChanged` invalidates caches and repaints everything).
4. `Themes/*.lua`: token tables registered into `ns.ThemeRegistry`. Colour tokens are `{ r, g, b, a }` with optional `accent`, `channel`, `shade`, `darken`, `lighten` markers; `Themes/Flat.lua` documents the schema.
5. `Design.lua`: builds and paints the bar and buttons from the active theme and owns the visual state machine (hover, press, active, alert). Solids go through `SetGradient` too, because `SetColorTexture` doesn't clear an earlier gradient.
6. `ChatBar.lua`: settings, events, the button pool, channel switching, history cycling, slash commands, the global keybinding entry points.
7. `EditMode.lua` and `EditModeDialog.lua`: HUD Edit Mode support (Retail and Forever only).
8. `Config.lua`: the settings panel (a canvas registered with `Settings.RegisterCanvasLayoutCategory`).

Rules that aren't obvious from one file:

- Always go through `ChatBar:GetSettings()`. `ns.db.profileMode` picks `ChatBarDB` (account) or `ChatBarCharDB` (character). Anything that replaces the profile in effect must end in `ChatBar:OnProfileChanged()`, which re-reads the cached selection, accent and bar position.
- `ChatBar:UpdateButtons()` skips the rebuild when the visible channel list is unchanged, so roster and channel events don't restyle every button or cut alerts short. Changes to how buttons *look* go through `ChatBar:Refresh()`, which forces it.
- Channel switches, from a button or a keybind, go through `ChatBar:ActivateChannel`. `ChatFrameUtil.OpenChat` applies its text on the next frame and runs `ParseText` on it, so text passed with a slash command is parsed: never append the player's message after `/w`.
- The bar's selection is the channel the next message goes to. `PointEditBoxAt` sets it as the edit box's sticky type as well as its chat type, because after a send Blizzard keeps only types whose `ChatTypeInfo` entry has `sticky = 1` (Yell, Emote and Raid Warning don't). Login and reload re-apply the remembered selection the same way.
- Whisper is one button for both kinds: it opens `SLASH_SMART_WHISPER1` (the client's localized `/w`), which resolves BattleTags and Battle.net friends itself. There is no `/bw` command, and no `BATTLEGROUND` chat type on Retail (both checked in game 2026-10-24); battlegrounds use Instance chat.
- Dropdowns are `DropdownButton` + `WowStyle1DropdownTemplate` (`Config.CreateDropdown`); `UIDropDownMenu` is deprecated and `EasyMenu` is gone.
- Colour pickers report every colour through `swatchFunc`, including the one set on open. Capture the state to restore before calling `SetupColorPickerAndShow`; Cancel, Escape and a click outside all call `cancelFunc`.
- Radio buttons are CheckButtons: a click on the selected one unchecks it, so each handler re-checks itself.
- Slider `OnValueChanged` handlers return early on an unchanged value, because `RefreshPanel` drives `SetValue`.

### HUD Edit Mode

The bar joins Edit Mode without being an Edit Mode *system*: systems are saved into server-side layouts and driven by secure code an addon frame can't join without taint.

- The overlay is an `EditModeSystemSelectionTemplate` frame with its `OnMouseDown` / `OnDragStart` / `OnDragStop` replaced (the stock ones only work for registered systems).
- Follow `EditModeManagerFrame`'s `OnShow` / `OnHide`, not the `EditMode.Enter` / `Exit` callbacks: the frame also hides when a panel opens over Edit Mode.
- `EditModeManagerFrame:ClearSelectedSystem()` is safe from addon code out of combat. Never call `SelectSystem` with the bar.
- The position is the profile's `barPosition`, saved on drop. Edit Mode ignores `lockPosition` on purpose.
- The dialog is built from the templates under Blizzard's setting widgets (`DialogBorderTranslucentTemplate`, `MinimalSliderWithSteppersTemplate`, `WowStyle1DropdownTemplate`), because those widgets write into Edit Mode layouts. Use `UIPanelCloseButtonNoScripts`; `UIPanelCloseButton` goes through `HideUIPanel` and taints.
- Closing the dialog and deselecting the bar are one action. Keep `Deselect` before `selection:Hide()`.

### Flavors

| Client | Interface | Family |
| --- | --- | --- |
| Retail (Midnight) | 120105, 120100, 120007, 120005 | Mainline |
| WoW: Forever | 16001 | Mainline |
| Mists Classic | 50504 | Classic |
| Classic Era | 11509 | Classic |

- Detect capabilities, never versions: Forever reports 16001, so a build-number check sends a Mainline client down the Classic path. The `ChatFrameUtil` checks with `ChatEdit_*` fallbacks in `ChatBar.lua` are the house pattern.
- Forever is Mainline: `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` and the 12.x API.
- Blizzard's chat UI (`Blizzard_ChatFrameBase/Shared/`) is the same on every flavor, so `ChatFrameUtil` and every chat type exist everywhere.
- `.pkgmeta` must not set `enable-toc-creation`; the single comma-separated `## Interface:` list is the alternative strategy, and mixing them silently produces no per-flavor TOCs.

### 12.x constraints

- Secret Values: `editBox:GetText()` on a whisper box and chat-event payload fields can be secrets. Check `issecretvalue(value)` before `#`, concatenation or comparison; all of them error on a secret.
- `editBox:UpdateHeader()` does width maths over secret whisper-name geometry. It's safe on the click and keybind paths; don't call it from a hook on Blizzard's temporary-window creation chain.
- `FCF_SavePositionAndDimensions` is post-hooked with a one-frame deferral; synchronous layout work inside that chain taints the dock state.

## Common tasks

- **New chat channel:** `ns.Defaults.channels` and `ns.ChannelInfo` in `ChatBar.lua`, a `CHAT_<NAME>` key in `Locales/enUS.lua` and every translation, availability in `ChatBar:IsChannelAvailable`, a binding in `Bindings.xml` plus its `BINDING_NAME_*` string. The settings checkbox is generated from `ns.ChannelInfo`.
- **New theme:** `Themes/<Name>.lua` listed in the TOC before `Design.lua`, `THEME_<NAME>` and `THEME_<NAME>_DESC` keys. Express the look in tokens and gradients only.
- **New setting:** a default in `ns.Defaults` (merged into old profiles by `MergeDefaults`), a control in `Config.lua` and its `RefreshPanel` line, and repair rules in `ChatBar:ValidateProfile` if a stored value can go stale. Bump `ns.Defaults.version` and add a branch to `MigrateProfile` only when an existing value changes meaning.
- **New UI string:** add it to `Locales/enUS.lua` and translate it in every locale file, using each client's own terms (Ketho's BlizzardInterfaceResources GlobalStrings). The bar is "Leiste" in deDE, "barra" in esES, "barre" in frFR, "바" in koKR, "панель" in ruRU.

## Release

- `/bump-up` adds a new client build to `## Interface:`, bumps `ChatBar.VERSION` and writes `RELEASE_NOTES.md`. `/release` commits, tags `vX.Y.Z` and pushes.
- Pushing a tag runs `.github/workflows/release.yml` (BigWigsMods packager), which uploads to CurseForge project 1443471 with the `CF_API_KEY` secret. Tags containing `alpha` or `beta` upload as that release type. GitHub: `MadSandwich/chatbar`, branch `develop`.
- `ChatBar.VERSION` in `ChatBar.lua` is the version; the TOC's `## Version: @project-version@` is filled in by the packager.
- Ignore guidance from the DennysOliveira `wow-addon-dev` plugin: it hard-codes `Interface 120001`, which contradicts the multi-flavor list above.
