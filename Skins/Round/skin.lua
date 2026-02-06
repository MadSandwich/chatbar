-- ChatBar Skin: Round
-- Modern semi-transparent effect with round buttons

local addonName, ns = ...

-- Register skin with the Textures module
if not ns.SkinRegistry then ns.SkinRegistry = {} end

ns.SkinRegistry["Round"] = {
    -- Metadata
    name = "Round",
    author = "ChatBar Team",
    description = "Modern semi-transparent effect with round buttons",
    shape = "round",
    
    -- Bar settings
    showBar = false,
    barOpacity = 0.5,
    barPadding = 4,
    
    -- Button settings
    hideButtonBorder = true,
    buttonSpacing = 2,
    
    -- Texture files (relative to skin folder)
    textures = {
        button_bg = "button_bg",
        button_border = "button_border",
        button_highlight = "button_highlight",
        button_pushed = "button_pushed",
        button_glow = "button_glow",
        button_mask = "button_mask",
        bar_bg = "bar_bg",
        bar_border = "bar_border",
    },
    
    -- Fallback colors (used if textures not found, tinted by channel color)
    colors = {
        background = { r = 0.1, g = 0.15, b = 0.2, a = 0.7 },
        border = { r = 0.4, g = 0.5, b = 0.6, a = 0.8 },
        highlight = { r = 0.6, g = 0.8, b = 1.0, a = 0.4 },
        pushed = { r = 0.05, g = 0.1, b = 0.15, a = 0.85 },
        glow = { r = 0.0, g = 1.0, b = 1.0, a = 0.8 },
    },
    
    -- Text settings
    fontSize = 12,
    textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    textShadow = true,
}
