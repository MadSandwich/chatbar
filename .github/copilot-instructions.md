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
- Access shared modules via `ns.ChatBar`, `ns.Textures`, `ns.L`, etc.

### 2. File Loading Order (Critical!)
**`ChatBar.toc`** defines load order—FILES MUST BE ORDERED CORRECTLY:
1. **Locales/** - Must load first (provides `ns.L` translation table)
2. **Skins/** - Must load before `Textures.lua` (populates `ns.SkinRegistry`)
3. **Textures.lua** - Requires skin registry
4. **ChatBar.lua** - Core logic (references all modules)
5. **Config.lua** - Settings UI (references ChatBar, Textures, L)

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

### 5. Skin Registry (Plugin Architecture)
Skins register themselves by populating `ns.SkinRegistry`:
```lua
-- In Skins/Default/skin.lua:
ns.SkinRegistry["Default"] = {
    name = "Default",
    author = "ChatBar Team",
    shape = "square",
    textures = { button_bg = "button_bg", ... },
    colors = { background = {r=0.12, g=0.12, b=0.12, a=0.85}, ... }
}
```
- Skins are hot-swappable at runtime
- Textures module (`ns.Textures`) loads skins and applies to frames
- Adding new skin: Create folder in `Skins/`, add `skin.lua`, register in TOC before `Textures.lua`

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

### 7. Button Pooling Pattern
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

-- Read/write text:
local text = editBox:GetText()
editBox:SetText("new text")
editBox:SetCursorPosition(#text)
```

### Frame Creation and Textures
```lua
-- Create frame:
local frame = CreateFrame("Frame", "UniqueName", parent)
frame:SetSize(100, 30)
frame:SetPoint("CENTER")

-- Add textures:
local texture = frame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints()
texture:SetTexture("Interface\\AddOns\\ChatBar\\Skins\\Default\\button_bg")
texture:SetVertexColor(0.5, 0.5, 0.5, 1.0)  -- RGBA tinting
```

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
2. Create UI controls in [Config.lua](d:\Projects\chatbar\Config.lua) using `Settings.RegisterVerticalLayoutCategory()`
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
1. Place addon in `World of Warcraft\_retail_\Interface\AddOns\ChatBar\`
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

- **[ChatBar.lua](d:\Projects\chatbar\ChatBar.lua)** (952 lines) - Core logic, event handlers, button management
- **[Textures.lua](d:\Projects\chatbar\Textures.lua)** (605 lines) - Skin system, texture loading, button styling
- **[Config.lua](d:\Projects\chatbar\Config.lua)** (486 lines) - Settings UI using modern Settings API
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

### Adding a New Skin
1. Create `Skins/SkinName/skin.lua`
2. Register in TOC before `Textures.lua` line
3. Populate `ns.SkinRegistry["SkinName"]` with texture paths and colors
4. Add texture files (TGA/BLP) to skin folder if not using color fallbacks

### Adding a Setting
1. Add to `ns.Defaults` with sensible default value
2. Use `ChatBar:MergeDefaults()` pattern for deep merging
3. Create UI control in Config.lua using Settings API
4. Hook control's OnClick/OnValueChanged to update `ChatBar:GetSettings()`

## Version Information
- **WoW Version:** 12.0.5+ (Midnight expansion)
- **Lua Version:** Lua 5.1 (WoW's embedded version)
- **Addon Version:** 2.2.1
- **API Level:** 120000, 120001, 120005 (Retail only, no Classic support)
