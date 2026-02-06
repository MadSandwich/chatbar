-- ChatBar: Skin-Based Texture Manager
-- Handles loading skins, creating button/bar textures, and live skin switching

local addonName, ns = ...

-- Create Textures module
local Textures = {}
ns.Textures = Textures

-- Skin system state
Textures.currentSkin = nil
Textures.skinPath = nil
Textures.availableSkins = {}

-- Constants
local ADDON_PATH = "Interface\\AddOns\\ChatBar\\Skins\\"
local BLIZZARD_CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

--[[ 
    Skin Loading System
]]

-- Get list of available skins from the registry
function Textures:GetAvailableSkins()
    local skins = {}
    
    if ns.SkinRegistry then
        for skinName, skinData in pairs(ns.SkinRegistry) do
            table.insert(skins, {
                id = skinName,
                name = skinData.name or skinName,
                description = skinData.description or "",
                author = skinData.author or "Unknown",
            })
        end
    end
    
    -- Sort alphabetically
    table.sort(skins, function(a, b)
        return a.name < b.name
    end)
    
    self.availableSkins = skins
    return skins
end

-- Load a skin by name
function Textures:LoadSkin(skinName)
    if not skinName then
        skinName = "Default"
    end
    
    -- Get skin data from registry
    local skinData = ns.SkinRegistry and ns.SkinRegistry[skinName]
    
    if not skinData then
        -- Fallback to Default if requested skin not found
        skinData = ns.SkinRegistry and ns.SkinRegistry["Default"]
        skinName = "Default"
        
        if not skinData then
            -- Create minimal fallback if no skins registered
            skinData = self:CreateFallbackSkin()
        end
    end
    
    self.currentSkin = skinData
    self.skinPath = ADDON_PATH .. skinName .. "\\"
    
    return skinData
end

-- Create fallback skin if none registered
function Textures:CreateFallbackSkin()
    return {
        name = "Fallback",
        author = "ChatBar",
        description = "Fallback color-based skin",
        shape = "square",
        barOpacity = 0.9,
        barPadding = 6,
        buttonSpacing = 1,
        textures = {},
        colors = {
            background = { r = 0.16, g = 0.16, b = 0.16, a = 0.9 },
            border = { r = 0.33, g = 0.33, b = 0.33, a = 1.0 },
            highlight = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 },
            pushed = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
            glow = { r = 1.0, g = 0.8, b = 0.0, a = 0.8 },
        },
        textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
        textShadow = true,
    }
end

-- Get current skin data
function Textures:GetCurrentSkin()
    if not self.currentSkin then
        self:LoadSkin("Default")
    end
    return self.currentSkin
end

-- Get texture path for current skin
function Textures:GetTexturePath(textureName)
    if not self.skinPath then
        self:LoadSkin("Default")
    end
    return self.skinPath .. textureName
end

--[[ 
    Button Texture Creation
]]

-- Create all texture layers for a button
function Textures:CreateButtonLayers(button, buttonSize)
    local skin = self:GetCurrentSkin()
    local size = buttonSize or 18
    local glowSize = size * 2 -- Glow is larger for soft edges
    
    -- Store size reference
    button.textureSize = size
    
    -- Layer order (bottom to top):
    -- BACKGROUND: bgTexture (channel-colored fill)
    -- BORDER: borderTexture (frame)
    -- ARTWORK: centerTexture (optional center detail)
    -- OVERLAY: glowTexture (notification flash, hidden by default)
    -- HIGHLIGHT: highlightTexture (hover effect)
    
    -- Background texture (main fill, tinted with channel color)
    local bgTexture = button:CreateTexture(nil, "BACKGROUND", nil, -8)
    bgTexture:SetSize(size, size)
    bgTexture:SetPoint("CENTER")
    bgTexture:SetSnapToPixelGrid(true)
    bgTexture:SetTexelSnappingBias(0)
    button.bgTexture = bgTexture
    
    -- Center texture (for additional detail/overlay)
    local centerTexture = button:CreateTexture(nil, "ARTWORK", nil, 0)
    centerTexture:SetSize(size, size)
    centerTexture:SetPoint("CENTER")
    centerTexture:SetBlendMode("BLEND")
    centerTexture:SetSnapToPixelGrid(true)
    centerTexture:SetTexelSnappingBias(0)
    button.centerTexture = centerTexture
    
    -- Border texture
    local borderTexture = button:CreateTexture(nil, "BORDER", nil, 0)
    borderTexture:SetSize(size, size)
    borderTexture:SetPoint("CENTER")
    borderTexture:SetSnapToPixelGrid(true)
    borderTexture:SetTexelSnappingBias(0)
    button.borderTexture = borderTexture
    
    -- Highlight texture (hover effect)
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT", nil, 0)
    highlightTexture:SetSize(size, size)
    highlightTexture:SetPoint("CENTER")
    highlightTexture:SetBlendMode("ADD")
    highlightTexture:SetSnapToPixelGrid(true)
    highlightTexture:SetTexelSnappingBias(0)
    button.highlightTexture = highlightTexture
    
    -- Pushed texture (click effect)
    local pushedTexture = button:CreateTexture(nil, "BACKGROUND", nil, -7)
    pushedTexture:SetSize(size, size)
    pushedTexture:SetPoint("CENTER")
    pushedTexture:SetSnapToPixelGrid(true)
    pushedTexture:SetTexelSnappingBias(0)
    pushedTexture:Hide()
    button.pushedTexture = pushedTexture
    
    -- Glow texture (notification flash, larger for soft edges)
    local glowTexture = button:CreateTexture(nil, "OVERLAY", nil, 7)
    glowTexture:SetSize(glowSize, glowSize)
    glowTexture:SetPoint("CENTER")
    glowTexture:SetBlendMode("ADD")
    glowTexture:Hide()
    button.glowTexture = glowTexture
    
    -- Apply mask if round shape
    if skin.shape == "round" then
        self:ApplyCircleMask(button)
    end
    
    -- Apply textures from skin
    self:ApplyButtonTextures(button)
    
    -- Setup button scripts for pushed state
    self:SetupButtonStateScripts(button)
    
    return button
end

-- Apply circle mask to button textures
function Textures:ApplyCircleMask(button)
    local size = button.textureSize or 18
    
    -- Create mask texture
    local mask = button:CreateMaskTexture()
    mask:SetSize(size, size)
    mask:SetPoint("CENTER")
    mask:SetTexture(BLIZZARD_CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    button.maskTexture = mask
    
    -- Apply mask to relevant textures
    if button.bgTexture then
        button.bgTexture:AddMaskTexture(mask)
    end
    if button.centerTexture then
        button.centerTexture:AddMaskTexture(mask)
    end
    if button.borderTexture then
        button.borderTexture:AddMaskTexture(mask)
    end
    if button.highlightTexture then
        button.highlightTexture:AddMaskTexture(mask)
    end
    if button.pushedTexture then
        button.pushedTexture:AddMaskTexture(mask)
    end
    -- Note: glow intentionally not masked for soft edge effect
end

-- Apply textures from current skin to button
function Textures:ApplyButtonTextures(button)
    local skin = self:GetCurrentSkin()
    local colors = skin.colors or {}
    
    -- Try to load texture files, fallback to colors
    local bgPath = self:GetTexturePath(skin.textures.button_bg or "button_bg")
    local borderPath = self:GetTexturePath(skin.textures.button_border or "button_border")
    local highlightPath = self:GetTexturePath(skin.textures.button_highlight or "button_highlight")
    local pushedPath = self:GetTexturePath(skin.textures.button_pushed or "button_pushed")
    local glowPath = self:GetTexturePath(skin.textures.button_glow or "button_glow")
    
    -- Apply background (will be tinted with channel color later)
    if button.bgTexture then
        button.bgTexture:SetTexture(bgPath)
        -- Fallback to white color if texture doesn't exist (white base allows proper vertex color tinting)
        if not button.bgTexture:GetTexture() then
            local c = colors.background or { r = 1.0, g = 1.0, b = 1.0, a = 0.9 }
            button.bgTexture:SetColorTexture(1.0, 1.0, 1.0, c.a)
            button.bgTexture.isColorFallback = true
        else
            button.bgTexture.isColorFallback = false
        end
    end
    
    -- Apply border (check skin.hideButtonBorder)
    if button.borderTexture then
        if skin.hideButtonBorder then
            button.borderTexture:Hide()
        else
            button.borderTexture:Show()
            button.borderTexture:SetTexture(borderPath)
            if not button.borderTexture:GetTexture() then
                local c = colors.border or { r = 0.4, g = 0.4, b = 0.4, a = 1.0 }
                button.borderTexture:SetColorTexture(c.r, c.g, c.b, c.a)
            end
        end
    end
    
    -- Apply highlight
    if button.highlightTexture then
        button.highlightTexture:SetTexture(highlightPath)
        if not button.highlightTexture:GetTexture() then
            local c = colors.highlight or { r = 1.0, g = 1.0, b = 1.0, a = 0.3 }
            button.highlightTexture:SetColorTexture(c.r, c.g, c.b, c.a)
        end
    end
    
    -- Apply pushed
    if button.pushedTexture then
        button.pushedTexture:SetTexture(pushedPath)
        if not button.pushedTexture:GetTexture() then
            local c = colors.pushed or { r = 0.1, g = 0.1, b = 0.1, a = 0.9 }
            button.pushedTexture:SetColorTexture(c.r, c.g, c.b, c.a)
        end
    end
    
    -- Apply glow
    if button.glowTexture then
        button.glowTexture:SetTexture(glowPath)
        if not button.glowTexture:GetTexture() then
            local c = colors.glow or { r = 1.0, g = 0.8, b = 0.0, a = 0.8 }
            button.glowTexture:SetColorTexture(c.r, c.g, c.b, c.a)
        end
    end
    
    -- Hide center texture by default (used for optional overlays)
    if button.centerTexture then
        button.centerTexture:Hide()
    end
end

-- Setup button state scripts for pushed appearance
function Textures:SetupButtonStateScripts(button)
    button:HookScript("OnMouseDown", function(self)
        if self.pushedTexture then
            self.pushedTexture:Show()
        end
        if self.bgTexture then
            self.bgTexture:SetAlpha(0.7)
        end
    end)
    
    button:HookScript("OnMouseUp", function(self)
        if self.pushedTexture then
            self.pushedTexture:Hide()
        end
        if self.bgTexture then
            self.bgTexture:SetAlpha(1.0)
        end
    end)
end

-- Apply channel color to button textures
function Textures:ApplyChannelColor(button, chatColor)
    if not chatColor then return end
    
    local r, g, b = chatColor.r, chatColor.g, chatColor.b
    
    -- Store for refresh
    button.channelColor = chatColor
    
    -- Tint background with channel color
    if button.bgTexture then
        button.bgTexture:SetVertexColor(r, g, b)
    end
    
    -- Tint glow with channel color (matches channel for notification)
    if button.glowTexture then
        button.glowTexture:SetVertexColor(r, g, b)
    end
    
    -- Optional: tint highlight slightly with channel color
    if button.highlightTexture then
        -- Blend channel color with white for subtle tint
        button.highlightTexture:SetVertexColor(
            0.7 + r * 0.3,
            0.7 + g * 0.3,
            0.7 + b * 0.3
        )
    end
end

-- Refresh button textures (for skin hot-swap)
function Textures:RefreshButtonTextures(button)
    if not button then return end
    
    local skin = self:GetCurrentSkin()
    
    -- Update texture paths
    self:ApplyButtonTextures(button)
    
    -- Reapply mask if shape changed
    if button.maskTexture then
        -- Remove old mask
        if button.bgTexture then
            button.bgTexture:RemoveMaskTexture(button.maskTexture)
        end
        if button.centerTexture then
            button.centerTexture:RemoveMaskTexture(button.maskTexture)
        end
        if button.borderTexture then
            button.borderTexture:RemoveMaskTexture(button.maskTexture)
        end
        if button.highlightTexture then
            button.highlightTexture:RemoveMaskTexture(button.maskTexture)
        end
        if button.pushedTexture then
            button.pushedTexture:RemoveMaskTexture(button.maskTexture)
        end
        button.maskTexture = nil
    end
    
    -- Reapply mask if round shape
    if skin.shape == "round" then
        self:ApplyCircleMask(button)
    end
    
    -- Reapply channel color if stored
    if button.channelColor then
        self:ApplyChannelColor(button, button.channelColor)
    end
end

-- Resize button textures
function Textures:ResizeButtonTextures(button, newSize)
    if not button then return end
    
    local glowSize = newSize * 2
    button.textureSize = newSize
    
    if button.bgTexture then
        button.bgTexture:SetSize(newSize, newSize)
    end
    if button.centerTexture then
        button.centerTexture:SetSize(newSize, newSize)
    end
    if button.borderTexture then
        button.borderTexture:SetSize(newSize, newSize)
    end
    if button.highlightTexture then
        button.highlightTexture:SetSize(newSize, newSize)
    end
    if button.pushedTexture then
        button.pushedTexture:SetSize(newSize, newSize)
    end
    if button.glowTexture then
        button.glowTexture:SetSize(glowSize, glowSize)
    end
    if button.maskTexture then
        button.maskTexture:SetSize(newSize, newSize)
    end
end

-- Clean up button textures
function Textures:CleanupButton(button)
    if not button then return end
    
    local texturesToClean = {
        "bgTexture", "centerTexture", "borderTexture",
        "highlightTexture", "pushedTexture", "glowTexture", "maskTexture"
    }
    
    for _, texName in ipairs(texturesToClean) do
        if button[texName] then
            button[texName]:Hide()
            button[texName]:ClearAllPoints()
            button[texName] = nil
        end
    end
    
    -- Clear channel color reference
    button.channelColor = nil
    
    -- Clear legacy texture references
    button.normalTextureBg = nil
    button.pushedTextureBg = nil
    button.highlightTextureBg = nil
    button.borderTextures = nil
end

--[[ 
    Bar Texture Creation
]]

-- Create bar textures
function Textures:CreateBarTextures(bar)
    -- Background texture (stretched to fill bar)
    local bgTexture = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
    bgTexture:SetAllPoints()
    bar.bgTexture = bgTexture
    
    -- Border texture (stretched to fill bar)
    local borderTexture = bar:CreateTexture(nil, "BORDER", nil, 0)
    borderTexture:SetAllPoints()
    bar.borderTexture = borderTexture
    
    -- Apply textures
    self:ApplyBarTextures(bar)
    
    return bar
end

-- Apply bar textures from current skin
function Textures:ApplyBarTextures(bar)
    local skin = self:GetCurrentSkin()
    local colors = skin.colors or {}
    
    -- Check if skin wants to hide the bar entirely (buttons only mode)
    if skin.showBar == false then
        if bar.bgTexture then
            bar.bgTexture:Hide()
        end
        if bar.borderTexture then
            bar.borderTexture:Hide()
        end
        return
    end
    
    local bgPath = self:GetTexturePath(skin.textures.bar_bg or "bar_bg")
    local borderPath = self:GetTexturePath(skin.textures.bar_border or "bar_border")
    
    -- Apply background
    if bar.bgTexture then
        bar.bgTexture:Show()
        bar.bgTexture:SetTexture(bgPath)
        if not bar.bgTexture:GetTexture() then
            local c = colors.background or { r = 1.0, g = 1.0, b = 1.0, a = 0.9 }
            bar.bgTexture:SetColorTexture(1.0, 1.0, 1.0, c.a)
        end
        bar.bgTexture:SetAlpha(skin.barOpacity or 0.9)
    end
    
    -- Apply border
    if bar.borderTexture then
        bar.borderTexture:Show()
        bar.borderTexture:SetTexture(borderPath)
        if not bar.borderTexture:GetTexture() then
            local c = colors.border or { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }
            bar.borderTexture:SetColorTexture(c.r, c.g, c.b, c.a)
        end
    end
end

-- Refresh bar textures (for skin hot-swap)
function Textures:RefreshBarTextures(bar)
    if not bar then return end
    self:ApplyBarTextures(bar)
end

--[[ 
    Flash Animation System
]]

-- Create flash animation group for a button
function Textures:CreateFlashAnimation(button)
    if not button.glowTexture then return end
    
    local glow = button.glowTexture
    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("REPEAT")
    
    -- Phase 1: Fade in + Scale up
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(0.8)
    fadeIn:SetDuration(0.4)
    fadeIn:SetSmoothing("IN_OUT")
    fadeIn:SetOrder(1)
    
    local scaleUp = ag:CreateAnimation("Scale")
    scaleUp:SetScaleFrom(0.9, 0.9)
    scaleUp:SetScaleTo(1.15, 1.15)
    scaleUp:SetDuration(0.4)
    scaleUp:SetSmoothing("IN_OUT")
    scaleUp:SetOrder(1)
    scaleUp:SetOrigin("CENTER", 0, 0)
    
    -- Phase 2: Fade out + Scale down
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.8)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.4)
    fadeOut:SetSmoothing("IN_OUT")
    fadeOut:SetOrder(2)
    
    local scaleDown = ag:CreateAnimation("Scale")
    scaleDown:SetScaleFrom(1.15, 1.15)
    scaleDown:SetScaleTo(0.9, 0.9)
    scaleDown:SetDuration(0.4)
    scaleDown:SetSmoothing("IN_OUT")
    scaleDown:SetOrder(2)
    scaleDown:SetOrigin("CENTER", 0, 0)
    
    button.flashAnim = ag
    
    return ag
end

-- Start flash animation
function Textures:StartFlash(button)
    if not button then return end
    
    -- Create animation if doesn't exist
    if not button.flashAnim then
        self:CreateFlashAnimation(button)
    end
    
    if button.glowTexture and button.flashAnim then
        button.glowTexture:SetAlpha(0)
        button.glowTexture:Show()
        button.flashAnim:Play()
        button.isFlashing = true
    end
end

-- Stop flash animation
function Textures:StopFlash(button)
    if not button then return end
    
    if button.flashAnim then
        button.flashAnim:Stop()
    end
    
    if button.glowTexture then
        button.glowTexture:Hide()
        button.glowTexture:SetAlpha(0)
    end
    
    button.isFlashing = false
end
