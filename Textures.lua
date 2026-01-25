-- ChatBar: Custom Texture and Shape Manager
-- Textures file

local addonName, ns = ...

-- Create Textures object
local Textures = {}
ns.Textures = Textures

--[[
    This module provides programmatic texture generation for button shapes.
    We support both round and square button shapes with customizable borders and colors.
]]

-- Helper function to create a solid color texture
function Textures:CreateColorTexture(frame, color, alpha)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetColorTexture(color.r, color.g, color.b, alpha or color.a)
    return texture
end

-- Helper function to draw a circle mask (approximation using  texture coordinates)
-- For true circular buttons, we'll use SetTexCoord to create rounded corners
function Textures:ApplyRoundedCorners(texture, size, radius)
    -- Calculate texture coordinates for rounded corners
    -- This creates an approximation of rounded corners by trimming the texture
    local cornerCut = radius / size
    
    if cornerCut > 0 and cornerCut < 0.5 then
        -- Apply subtle corner rounding by adjusting texture coordinates
        -- Note: This is a simple approach; for perfect circles, you'd need custom artwork
        texture:SetTexCoord(
            cornerCut, 1 - cornerCut,  -- left, right
            cornerCut, 1 - cornerCut   -- top, bottom
        )
    end
end

-- Create round button textures
function Textures:CreateRoundButton(button, theme, chatColor)
    local size = theme.size or 24
    local borderSize = theme.borderSize or 2
    
    -- Calculate radius for rounded corners (half size makes it circular)
    local radius = size / 2
    
    -- Create circular mask texture FIRST
    -- Use the built-in CharacterCreate circle mask atlas
    local mask = button:CreateMaskTexture()
    mask:SetSize(size, size)
    mask:SetPoint("CENTER")
    -- Use Blizzard's built-in circular mask texture
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    button.maskTexture = mask
    
    -- Determine colors to use
    local normalR, normalG, normalB, normalA
    if theme.fullChannelColor and chatColor then
        -- Use full channel color
        normalR, normalG, normalB = chatColor.r, chatColor.g, chatColor.b
        normalA = theme.normalColor.a
    else
        -- Use theme color
        normalR, normalG, normalB = theme.normalColor.r, theme.normalColor.g, theme.normalColor.b
        normalA = theme.normalColor.a
    end
    
    -- Normal state texture (background)
    local normalBg = button:CreateTexture(nil, "BACKGROUND", nil, -8)
    normalBg:SetSize(size, size)
    normalBg:SetPoint("CENTER")
    normalBg:SetColorTexture(normalR, normalG, normalB, normalA)
    normalBg:AddMaskTexture(mask)
    button.normalTextureBg = normalBg
    
    -- Border (ring around the circle)
    if borderSize > 0 then
        local border = button:CreateTexture(nil, "BORDER")
        border:SetSize(size + borderSize * 2, size + borderSize * 2)
        border:SetPoint("CENTER")
        border:SetColorTexture(
            theme.borderColor.r,
            theme.borderColor.g,
            theme.borderColor.b,
            theme.borderColor.a
        )
        border:AddMaskTexture(mask)
        button.borderTexture = border
    end
    
    -- Pushed state texture
    local pushedR, pushedG, pushedB, pushedA
    if theme.fullChannelColor and chatColor then
        -- Use darker version of channel color
        pushedR, pushedG, pushedB = chatColor.r * 0.7, chatColor.g * 0.7, chatColor.b * 0.7
        pushedA = theme.pushedColor.a
    else
        -- Use theme color
        pushedR, pushedG, pushedB = theme.pushedColor.r, theme.pushedColor.g, theme.pushedColor.b
        pushedA = theme.pushedColor.a
    end
    
    local pushedBg = button:CreateTexture(nil, "BACKGROUND", nil, -7)
    pushedBg:SetSize(size, size)
    pushedBg:SetPoint("CENTER")
    pushedBg:SetColorTexture(pushedR, pushedG, pushedB, pushedA)
    pushedBg:AddMaskTexture(mask)
    button.pushedTextureBg = pushedBg
    
    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(size, size)
    highlight:SetPoint("CENTER")
    highlight:SetBlendMode("ADD")
    highlight:SetColorTexture(
        theme.highlightColor.r,
        theme.highlightColor.g,
        theme.highlightColor.b,
        theme.highlightColor.a
    )
    highlight:AddMaskTexture(mask)
    button.highlightTextureBg = highlight
    
    -- Note: We don't call SetNormalTexture/SetPushedTexture/SetHighlightTexture here
    -- because those methods expect file paths or atlas names, not texture objects.
    -- Our manually created textures are already properly configured and anchored.
    
    return button
end

-- Create square button textures with optional rounded corners
function Textures:CreateSquareButton(button, theme)
    local size = theme.size or 24
    local borderSize = theme.borderSize or 2
    local cornerRadius = theme.cornerRadius or 0
    
    -- Normal state texture (background)
    local normalBg = button:CreateTexture(nil, "BACKGROUND", nil, -8)
    normalBg:SetSize(size, size)
    normalBg:SetPoint("CENTER")
    normalBg:SetColorTexture(
        theme.normalColor.r,
        theme.normalColor.g,
        theme.normalColor.b,
        theme.normalColor.a
    )
    
    -- Apply rounded corners if specified
    if cornerRadius > 0 then
        self:ApplyRoundedCorners(normalBg, size, cornerRadius)
    end
    button.normalTextureBg = normalBg
    
    -- Border (frame around the square)
    if borderSize > 0 then
        -- Create 4 border pieces (top, bottom, left, right)
        -- Top border
        local borderTop = button:CreateTexture(nil, "BORDER")
        borderTop:SetSize(size + borderSize * 2, borderSize)
        borderTop:SetPoint("TOP", button, "TOP", 0, borderSize)
        borderTop:SetColorTexture(
            theme.borderColor.r,
            theme.borderColor.g,
            theme.borderColor.b,
            theme.borderColor.a
        )
        
        -- Bottom border
        local borderBottom = button:CreateTexture(nil, "BORDER")
        borderBottom:SetSize(size + borderSize * 2, borderSize)
        borderBottom:SetPoint("BOTTOM", button, "BOTTOM", 0, -borderSize)
        borderBottom:SetColorTexture(
            theme.borderColor.r,
            theme.borderColor.g,
            theme.borderColor.b,
            theme.borderColor.a
        )
        
        -- Left border
        local borderLeft = button:CreateTexture(nil, "BORDER")
        borderLeft:SetSize(borderSize, size)
        borderLeft:SetPoint("LEFT", button, "LEFT", -borderSize, 0)
        borderLeft:SetColorTexture(
            theme.borderColor.r,
            theme.borderColor.g,
            theme.borderColor.b,
            theme.borderColor.a
        )
        
        -- Right border
        local borderRight = button:CreateTexture(nil, "BORDER")
        borderRight:SetSize(borderSize, size)
        borderRight:SetPoint("RIGHT", button, "RIGHT", borderSize, 0)
        borderRight:SetColorTexture(
            theme.borderColor.r,
            theme.borderColor.g,
            theme.borderColor.b,
            theme.borderColor.a
        )
        
        button.borderTextures = {borderTop, borderBottom, borderLeft, borderRight}
    end
    
    -- Pushed state texture
    local pushedBg = button:CreateTexture(nil, "BACKGROUND", nil, -7)
    pushedBg:SetSize(size, size)
    pushedBg:SetPoint("CENTER")
    pushedBg:SetColorTexture(
        theme.pushedColor.r,
        theme.pushedColor.g,
        theme.pushedColor.b,
        theme.pushedColor.a
    )
    if cornerRadius > 0 then
        self:ApplyRoundedCorners(pushedBg, size, cornerRadius)
    end
    button.pushedTextureBg = pushedBg
    
    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(size, size)
    highlight:SetPoint("CENTER")
    highlight:SetBlendMode("ADD")
    highlight:SetColorTexture(
        theme.highlightColor.r,
        theme.highlightColor.g,
        theme.highlightColor.b,
        theme.highlightColor.a
    )
    if cornerRadius > 0 then
        self:ApplyRoundedCorners(highlight, size, cornerRadius)
    end
    button.highlightTextureBg = highlight
    
    -- Note: We don't call SetNormalTexture/SetPushedTexture/SetHighlightTexture here
    -- because those methods expect file paths or atlas names, not texture objects.
    -- Our manually created textures are already properly configured and anchored.
    
    return button
end

-- Apply channel color to button
function Textures:ApplyChannelColor(button, chatColor, theme)
    if not chatColor or not button.normalTextureBg then return end
    
    -- Tint the button with the chat channel color
    local r, g, b = chatColor.r, chatColor.g, chatColor.b
    
    -- Apply to normal state
    if button.normalTextureBg then
        if theme and theme.fullChannelColor then
            -- Use full channel color (classic/round themes)
            button.normalTextureBg:SetColorTexture(
                r,
                g,
                b,
                button.normalTextureBg.baseA or theme.normalColor.a or 0.9
            )
        else
            -- Blend with base color for other themes
            local factor = 0.4 -- How much to blend with channel color
            local nr = button.normalTextureBg.baseR or 0.25
            local ng = button.normalTextureBg.baseG or 0.25
            local nb = button.normalTextureBg.baseB or 0.25
            
            button.normalTextureBg:SetColorTexture(
                nr * (1 - factor) + r * factor,
                ng * (1 - factor) + g * factor,
                nb * (1 - factor) + b * factor,
                button.normalTextureBg.baseA or 0.8
            )
        end
    end
    
    -- Apply to pushed state
    if button.pushedTextureBg then
        if theme and theme.fullChannelColor then
            -- Use darker version of channel color
            button.pushedTextureBg:SetColorTexture(
                r * 0.7,
                g * 0.7,
                b * 0.7,
                button.pushedTextureBg.baseA or theme.pushedColor.a or 1.0
            )
        end
    end
    
    -- Border gets the full channel color
    if button.borderTexture then
        button.borderTexture:SetColorTexture(r, g, b, 1)
    elseif button.borderTextures then
        for _, border in ipairs(button.borderTextures) do
            border:SetColorTexture(r, g, b, 1)
        end
    end
end

-- Clean up textures when button theme changes
function Textures:CleanupButton(button)
    if button.normalTextureBg then
        button.normalTextureBg:Hide()
        button.normalTextureBg = nil
    end
    
    if button.pushedTextureBg then
        button.pushedTextureBg:Hide()
        button.pushedTextureBg = nil
    end
    
    if button.highlightTextureBg then
        button.highlightTextureBg:Hide()
        button.highlightTextureBg = nil
    end
    
    if button.borderTexture then
        button.borderTexture:Hide()
        button.borderTexture = nil
    end
    
    if button.borderTextures then
        for _, border in ipairs(button.borderTextures) do
            border:Hide()
        end
        button.borderTextures = nil
    end
    
    if button.maskTexture then
        button.maskTexture = nil
    end
end
