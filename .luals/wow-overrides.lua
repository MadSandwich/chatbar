---@meta
--- Local corrections to the Ketho WoW API annotations.
---
--- Definition-only: never listed in ChatBar.toc, never loaded by the game, and
--- excluded from the packaged addon via .pkgmeta. Delete an entry here once the
--- corresponding fix lands upstream in Ketho.wow-api.

--- Upstream annotates colorR/colorG/colorB as required, which makes every
--- `GameTooltip:SetText(text)` call report `missing-parameter`. The wiki and
--- Blizzard's own FrameXML both treat the colour arguments as optional.
--- https://warcraft.wiki.gg/wiki/API_GameTooltip_SetText
---@param text string
---@param colorR? number
---@param colorG? number
---@param colorB? number
---@param alpha? number
---@param wrap? boolean
function GameTooltip:SetText(text, colorR, colorG, colorB, alpha, wrap) end

--- Party category constants. Live globals -- Blizzard's FrameXML still uses
--- them -- but they have no upstream annotation, so they read as undefined.
---@type number
LE_PARTY_CATEGORY_HOME = 1
---@type number
LE_PARTY_CATEGORY_INSTANCE = 2
