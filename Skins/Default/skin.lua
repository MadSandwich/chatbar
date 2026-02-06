-- ChatBar Skin: Default
-- Classic dark theme with subtle gradients and square buttons

local addonName, ns = ...

-- Register skin with the Textures module
if not ns.SkinRegistry then ns.SkinRegistry = {} end

ns.SkinRegistry["Default"] = {
    -- Metadata
    name = "Default",
    author = "ChatBar Team",
    description = "Classic dark theme with subtle gradients",
    shape = "square",
    
    -- Bar settings
    showBar = true,
    barOpacity = 0.8,
    barPadding = 4,
    
    -- Button settings  
    buttonSpacing = 2,
    
    -- Texture files (relative to skin folder)
    textures = {
        button_bg = "button_bg",
        button_border = "button_border",
        button_highlight = "button_highlight",
        button_pushed = "button_pushed",
        button_glow = "button_glow",
        button_mask = "button_mask", -- Only used if shape = "round"
        bar_bg = "bar_bg",
        bar_border = "bar_border",
    },
    
    -- Fallback colors (used if textures not found, tinted by channel color)
    colors = {
        background = { r = 0.12, g = 0.12, b = 0.12, a = 0.85 },
        border = { r = 0.25, g = 0.25, b = 0.25, a = 0.6 },
        highlight = { r = 1.0, g = 1.0, b = 1.0, a = 0.2 },
        pushed = { r = 0.08, g = 0.08, b = 0.08, a = 0.9 },
        glow = { r = 1.0, g = 1.0, b = 1.0, a = 0.6 },
    },
    
    -- Text settings
    fontSize = 10,
    textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textShadow = false,
}
