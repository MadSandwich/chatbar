# ChatBar - AI Coding Agent Instructions

## Project Overview

ChatBar is a World of Warcraft addon providing a customizable chat channel switcher. This is a **WoW addon**, not a standard application—it runs inside the WoW game client using Blizzard's Lua 5.1 API with custom extensions.

## Critical Architecture Patterns

### 1. WoW Addon Namespace Pattern
All files use isolated namespace to avoid global pollution:
```lua
local addonName, ns = ...  -- Always first line
ns.ModuleName = {}         -- Register modules on namespace
```
- `ns` table is shared across all addon files
- Never pollute `_G` global namespace unless required (keybindings, slash commands)
- Access shared modules via `ns.ChatBar`, `ns.Design`, `ns.Theme`, `ns.Pixel`, `ns.L`, etc.

### 2. File Loading Order (Critical!)
**`ChatBar.toc`** defines load order—FILES MUST BE ORDERED CORRECTLY:
1. **Locales/** - Must load first (provides `ns.L`; themes reference `L` keys for their names)
2. **Core/Pixel.lua** - Pixel grid + border primitive, no dependencies
3. **Core/Theme.lua** - Theme tokens and accent resolution (uses `ns.L`)
4. **Themes/** - Each file registers itself into `ns.ThemeRegistry`
5. **Design.lua** - Design engine; captures `ns.Pixel` and `ns.Theme` at load
6. **ChatBar.lua** - Core logic (references all modules)
7. **Config.lua** - Settings UI (references ChatBar, Design, Theme, Pixel, L)

**Never change load order without understanding dependencies.**

### 3. Event-Driven Architecture
WoW is event-driven. Use `barFrame:RegisterEvent("EVENT_NAME")` then handle with:
```lua
barFrame:SetScript("OnEvent", function(frame, event, ...)
    if ChatBar[event] then
        ChatBar[event](ChatBar, ...)  -- Dispatches to ChatBar:EVENT_NAME()
    end
end)
```
- Event handlers are methods named after the event: `function ChatBar:PLAYER_ENTERING_WORLD()`
- See [ChatBar.lua#L253-L262](d:\Projects\chatbar\ChatBar.lua#L253-L262) for dispatcher pattern
- Common events: `ADDON_LOADED`, `PLAYER_ENTERING_WORLD`, `GROUP_ROSTER_UPDATE`, `CHANNEL_UI_UPDATE`

### 4. Dual-Profile SavedVariables System
Settings support account-wide OR per-character profiles:
```lua
-- In TOC:
## SavedVariables: ChatBarDB              -- Account-wide
## SavedVariablesPerCharacter: ChatBarCharDB  -- Per-character

-- Access via abstraction:
function ChatBar:GetSettings()
    if ns.db.profileMode == "character" then
        return ns.charDB  -- Per-character
    end
    return ns.db  -- Account-wide
end
```
Always use `ChatBar:GetSettings()`, never access `ns.db` or `ns.charDB` directly.

### 5. Theme Registry (Plugin Architecture)
There are **no texture files**. Themes are token tables registered into
`ns.ThemeRegistry`, and `ns.Design` paints frames from those tokens using
`SetColorTexture` / `SetGradient`:
```lua
-- In Themes/Flat.lua:
ns.ThemeRegistry["Flat"] = {
    order = 1,
    nameKey = "THEME_FLAT",       -- resolved through ns.L
    descKey = "THEME_FLAT_DESC",
    layout = { barPadding = 4, buttonSpacing = 2, defaultShape = "square", defaultFontSize = 12 },
    bar    = { show = true, fill = { 0.04, 0.05, 0.07, 0.72 }, border = { 1, 1, 1, 0.08 } },
    button = { fill = { 0.06, 0.09, 0.12, 0.60 }, channelTint = "stripe", ... },
    label  = { source = "white", alpha = 0.62, alphaHover = 0.88, ... },
    active = { indicator = "underline", size = 2, color = { 1, 1, 1, 1, accent = true } },
    alert  = { style = "stripe", ... },
}
```
- A colour token is `{ r, g, b, a }`, optionally carrying `accent = true` or
  `channel = true` (the literal r,g,b then act as the fallback), plus
  `lighten` / `darken`. `ns.Theme:Resolve(token, channelColor)` resolves it.
- Themes are hot-swappable at runtime; `ns.Theme:NotifyChanged(reason)` repaints
  everything already on screen.
- Adding a theme: create `Themes/Name.lua`, register in TOC **before**
  `Design.lua`, add `THEME_NAME` / `THEME_NAME_DESC` locale keys.

### 6. Localization with Fallback
Translation system uses metatable fallback:
```lua
local L = setmetatable({}, {
    __index = function(t, k) return k end  -- Returns key if translation missing
})
ns.L = L

-- Usage:
L.CHAT_SAY = "Say"  -- In Locales.lua (English base)
-- In deDE.lua: L.CHAT_SAY = "Sagen"
```
- Base locale: `Locales/Locales.lua` (enUS)
- Language files override specific keys
- Always use `ns.L.KEY_NAME` for user-facing text
- **Exception:** Keybinding names must be in `_G` (WoW requirement): `_G["BINDING_NAME_CHATBAR_TOGGLE"]`

### 7. Pixel-Perfect Borders
Never use `BackdropTemplate` for thin borders. `ns.Pixel.CreateBorder(frame, r, g, b, a)`
builds four `WHITE8X8` strips sized to `768 / screenHeight / effectiveScale`, with
`SetSnapToPixelGrid(false)` so a 1px edge never rounds away. Borders re-snap
automatically on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`.

### 8. Button Pooling Pattern
Reuses button frames for performance:
```lua
local buttonPool = {}    -- All created buttons
local activeButtons = {} -- Currently visible buttons

-- Get from pool or create new:
local button = table.remove(buttonPool) or CreateFrame("Button", nil, barFrame)
table.insert(activeButtons, button)

-- Return to pool when done:
button:Hide()
table.insert(buttonPool, button)
wipe(activeButtons)
```
See [ChatBar.lua#L382-L523](d:\Projects\chatbar\ChatBar.lua#L382-L523) for full implementation.

## WoW API Integration Patterns

### EditBox (Chat Input) Manipulation
```lua
-- Open chat with specific channel:
local editBox = ChatFrameUtil.OpenChat("", currentChatFrame)  -- Modern API (WoW 10.0+)
editBox:SetChatType("SAY")  -- Set channel type
editBox:UpdateHeader()      -- Update UI

-- For numbered channels:
editBox:SetAttribute("chatType", "CHANNEL")
editBox:SetAttribute("channelTarget", channelId)
ChatEdit_UpdateHeader(editBox)

-- Read/write text. Secret Values (12.0): a whisper edit box can return a
-- protected string, and #text, concatenation and comparison all error on one,
-- so the guard must come before any other use of the value.
local text = editBox:GetText()
if issecretvalue and issecretvalue(text) then text = nil end
if type(text) == "string" then
    editBox:SetCursorPosition(#text)
end
```

### Frame Creation and Textures
```lua
-- Create frame:
local frame = CreateFrame("Frame", "UniqueName", parent)
frame:SetSize(100, 30)
frame:SetPoint("CENTER")

-- Add textures. This addon ships no image files: every surface is WHITE8X8
-- painted with a colour or a gradient. Solids go through SetGradient too, with
-- both stops equal -- SetColorTexture does NOT clear a gradient set earlier on
-- the same texture, so mixing the two APIs leaves a stale gradient multiplying
-- the new colour.
local texture = frame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints()
texture:SetTexture("Interface\\Buttons\\WHITE8X8")
texture:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.9), CreateColor(0.1, 0.1, 0.1, 0.6))
```
Prefer `ns.Design` for anything the bar draws; go direct only inside the engine.

### Hooking Blizzard Functions
```lua
-- Use HookScript, not SetScript (prevents overwriting):
chatFrame.editBox:HookScript("OnEditFocusGained", function(editBox)
    self:OnChatFrameFocusGained(chatFrame)
end)
```

## Configuration & Settings

### Adding New Settings
1. Add to `ns.Defaults` in [ChatBar.lua#L14-L58](d:\Projects\chatbar\ChatBar.lua#L14-L58)
2. Create UI controls in [Config.lua](d:\Projects\chatbar\Config.lua). The panel is a canvas registered with `Settings.RegisterCanvasLayoutCategory()`; use `DropdownButton` + `WowStyle1DropdownTemplate` for dropdowns, never `UIDropDownMenuTemplate`
3. Access via `ChatBar:GetSettings().yourSettingName`
4. Settings auto-save to `ChatBarDB` or `ChatBarCharDB`

### Modern Settings API (WoW 10.0+)
Uses `Settings.RegisterVerticalLayoutCategory()` instead of legacy InterfaceOptions:
```lua
local category = Settings.RegisterVerticalLayoutCategory("ChatBar")
local subcategory = Settings.RegisterVerticalLayoutSubcategory(category, "Appearance")
Settings.RegisterAddOnCategory(category)
```

## Testing & Debugging

### Testing in WoW
1. Place addon in the client's AddOns folder (`_retail_`, `_classic_era_`,
   `_classic_`, or Forever's product folder) -- the single TOC loads on all of them
2. Launch WoW, `/reload` to test changes
3. Enable Lua errors: ESC → Interface → Help → Display Lua Errors
4. Use `/chatbar` to open settings
5. Use `/dump variable` in-game to inspect values

### Common Debug Patterns
```lua
-- Print to chat:
print("Debug:", value)
print(string.format("Value: %d", number))

-- Safe calls to prevent errors:
local success, result = pcall(function() return riskCode() end)

-- Check addon taint:
InCombatLockdown()  -- Returns true if in combat (action restrictions apply)
```

### Install BugSack/BugGrabber addons for error reporting

## Code Style Conventions

### Lua Patterns Used
- **Local first:** Always use `local` unless global required
- **Function style:** `function Object:Method()` (colon) for methods, `function name()` for standalone
- **Table construction:** Use trailing commas for multi-line tables
- **String formatting:** `string.format()` over concatenation for complex strings
- **Nil safety:** `value and value.field` short-circuit pattern

### Naming Conventions
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `ChatBar.VERSION`)
- **Functions:** `PascalCase` for public methods, `camelCase` for locals
- **Variables:** `camelCase` (e.g., `currentChatFrame`, `buttonPool`)
- **Tables:** `camelCase` (e.g., `ns.ChannelInfo`)

### Comments
- Use `--` for single line, `--[[ ]]` for blocks
- Document complex WoW API interactions
- Include version requirements for API calls: `-- WoW 10.0+ API`

## Key Files Reference

- **[ChatBar.lua](d:\Projects\chatbar\ChatBar.lua)** - Core logic, event handlers, button management
- **[Design.lua](d:\Projects\chatbar\Design.lua)** - Design engine: builds and paints the bar and buttons, owns the visual state machine
- **[Core/Pixel.lua](d:\Projects\chatbar\Core\Pixel.lua)** - Pixel grid, snapping helpers, 1px border primitive
- **[Core/Theme.lua](d:\Projects\chatbar\Core\Theme.lua)** - Theme tokens, accent resolution, colour helpers
- **[Config.lua](d:\Projects\chatbar\Config.lua)** - Settings UI using modern Settings API
- **[ChatBar.toc](d:\Projects\chatbar\ChatBar.toc)** - Addon manifest, file load order, metadata
- **[Locales/Locales.lua](d:\Projects\chatbar\Locales\Locales.lua)** - Base English translations
- **[Bindings.xml](d:\Projects\chatbar\Bindings.xml)** - Keybinding definitions

## Common Tasks

### Adding a New Chat Channel
1. Add to `ns.Defaults.channels` in [ChatBar.lua#L32-L51](d:\Projects\chatbar\ChatBar.lua#L32-L51)
2. Add to `ns.ChannelInfo` with `labelKey`, `command`, `requiresTarget` [ChatBar.lua#L64-L78](d:\Projects\chatbar\ChatBar.lua#L64-L78)
3. Add localization key `L.CHAT_NEWCHANNEL` in [Locales/Locales.lua](d:\Projects\chatbar\Locales\Locales.lua)
4. Add keybinding in [Bindings.xml](d:\Projects\chatbar\Bindings.xml)
5. Add checkbox in [Config.lua](d:\Projects\chatbar\Config.lua) channel section

### Adding a New Theme
1. Create `Themes/ThemeName.lua`
2. Register in TOC **before** the `Design.lua` line
3. Populate `ns.ThemeRegistry["ThemeName"]` -- copy `Themes/Flat.lua` for the full schema
4. Add `THEME_THEMENAME` / `THEME_THEMENAME_DESC` keys to `Locales/Locales.lua`
5. No image files: express the look in colour tokens and gradients

### Adding a Setting
1. Add to `ns.Defaults` with sensible default value
2. Use `ChatBar:MergeDefaults()` pattern for deep merging
3. Create UI control in Config.lua using Settings API
4. Hook control's OnClick/OnValueChanged to update `ChatBar:GetSettings()`

## Version Information
- **Lua Version:** Lua 5.1 (WoW's embedded version -- no `goto`, no bitwise operators, no integer division)
- **Addon Version:** 3.1.0
- **Supported flavors:** one package, one comma-separated `## Interface:` list.

| Client | Version | Interface | Family |
| --- | --- | --- | --- |
| Retail (Midnight) | 12.1.0 | 120100, 120007, 120005 | Mainline |
| WoW: Forever | 1.60.1 | 16001 | Mainline |
| Mists Classic | 5.5.4 | 50504 | Classic |
| Classic Era | 1.15.9 | 11509 | Classic |

### Writing flavor-portable code
- **Detect capabilities, never versions.** `if C_PvP and C_PvP.IsActiveBattlefield then`
  is correct; gating on `select(4, GetBuildInfo())` is not. Forever reports
  **16001**, so a `>= 100000` check silently sends a Mainline client down the
  Classic path. The existing `OpenChatWithFallback`, `ChatFrameUtil -> ChatEdit_*`
  and `ShapeAvailable` helpers are the house pattern -- follow them.
- **Forever is Mainline, not Classic.** `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE`,
  `[Family]` resolves to `Mainline`, and the API surface matches 12.1. Port from
  Retail code paths.
- **Blizzard's chat UI is shared across flavors.** `Blizzard_ChatFrameBase/Shared/`
  is the same on Classic Era as on Retail, so `ChatFrameUtil`, every chat type and
  `LE_PARTY_CATEGORY_INSTANCE` are available everywhere.
- **The only flavor-specific code** is the `BATTLEGROUND` branch of
  `ChatBar:IsChannelAvailable` -- `C_PvP.IsActiveBattlefield` is Mainline-only.
- **`.pkgmeta` must not set `enable-toc-creation`.** That strategy requires a
  `## Interface-<Type>:` line per flavor; the comma-list strategy used here is the
  alternative. Mixing them silently produces no per-flavor TOCs.

### 12.x constraints that touch this addon
- **Secret Values**: `editBox:GetText()` on a whisper edit box can return a
  protected string. Guard with `issecretvalue(text)` *before* `#text`,
  concatenation, or comparison -- all of them error on a secret.
- **`editBox:UpdateHeader()`** runs width math over secret whisper-name geometry.
  It is safe on the hardware-driven click path this addon uses; do not call it
  from inside a hook on Blizzard's own temporary-window creation chain.
- **`UIDropDownMenuTemplate`** is deprecated (11.0) and `EasyMenu` was removed.
  Use `DropdownButton` + `WowStyle1DropdownTemplate` with `MenuUtil`.
- The combat-log and aura restrictions that broke WeakAuras do not apply here --
  this addon reads no combat state.
