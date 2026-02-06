-- ChatBar Skin: Minimal
-- Clean, flat design with square buttons and thin borders

local addonName, ns = ...

-- Register skin with the Textures module
if not ns.SkinRegistry then ns.SkinRegistry = {} end

ns.SkinRegistry["Minimal"] = {
    -- Metadata
    name = "Minimal",
    author = "ChatBar Team",
    description = "Clean, flat design with minimal borders",
    shape = "square", -- "square" or "round"
    
    -- Bar settings
    showBar = false,
    barOpacity = 0,
    barPadding = 2,
    
    -- Button settings
    buttonSpacing = 2,
    
    -- Texture files (relative to skin folder)
    textures = {
        button_highlight = "button_highlight",
        button_pushed = "button_pushed",
        button_glow = "button_glow",
    },
    
    -- Fallback colors (used if textures not found, tinted by channel color)
    colors = {
        background = { r = 0.12, g = 0.12, b = 0.12, a = 0 },
        border = { r = 0.25, g = 0.25, b = 0.25, a = 0.6 },
        highlight = { r = 1.0, g = 1.0, b = 1.0, a = 0.2 },
        pushed = { r = 0.08, g = 0.08, b = 0.08, a = 0.9 },
        glow = { r = 1.0, g = 1.0, b = 1.0, a = 0.6 },
    },
    
    -- Text settings
    fontSize = 12,
    textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textShadow = false,
}
