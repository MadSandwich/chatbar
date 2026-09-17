-- ChatBar: Design engine
--
-- Replaces the old texture-file skin system. Every surface here is drawn from
-- theme tokens with SetColorTexture / SetGradient, so a theme is a Lua table
-- rather than a folder of .tga files: resolution independent, hot-swappable,
-- and free to ship.
--
-- The engine owns the visual state machine. Callers describe *what* a button
-- is (its channel, whether it is the active one, whether it is available) and
-- this file decides what that looks like under the current theme.

local addonName, ns = ...

local Design = {}
ns.Design = Design

local Pixel = ns.Pixel
local Theme = ns.Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Blizzard's portrait alpha mask, the one circular mask guaranteed to exist on
-- every client. Used for the round button shape.
local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- The rounded-square mask Blizzard cuts its own action bar icons with. It lets a
-- theme have rounded corners without ChatBar shipping a texture: it is client
-- art, present on every install, and a mask is sampled rather than blitted, so
-- it fits any button size.
--
-- No shipped theme asks for it at the moment -- both are square -- but a theme
-- turns it on with one token (`layout.defaultShape = "rounded"`), and the
-- machinery below is shared with the round shape either way.
--
-- Availability is checked at runtime rather than assumed. An atlas that
-- disappears in some future patch should cost the corners, not throw on every
-- button we draw.
local ROUNDED_MASK_ATLAS = "UI-HUD-ActionBar-IconFrame-Mask"

-- Shapes that need a mask, and what to cut them with. "square" is absent
-- deliberately: it is the no-mask case.
local SHAPES = {
    circle  = { file = CIRCLE_MASK },
    rounded = { atlas = ROUNDED_MASK_ATLAS },
}

local DEFAULT_THEME = "Flat"

Design.currentThemeId = nil
Design.currentTheme = nil

--[[
    Theme selection
]]

function Design:LoadTheme(themeId)
    local theme = themeId and Theme:Get(themeId)

    if not theme then
        themeId = DEFAULT_THEME
        theme = Theme:Get(DEFAULT_THEME)
    end

    -- Last resort: the registry failed to populate. Rather than nil-error every
    -- style call downstream, synthesise a usable dark theme.
    if not theme then
        themeId = "Fallback"
        theme = self:CreateFallbackTheme()
        ns.ThemeRegistry[themeId] = theme
    end

    self.currentThemeId = themeId
    self.currentTheme = theme
    return theme
end

function Design:GetTheme()
    if not self.currentTheme then
        self:LoadTheme(DEFAULT_THEME)
    end
    return self.currentTheme
end

function Design:GetThemeId()
    if not self.currentThemeId then
        self:LoadTheme(DEFAULT_THEME)
    end
    return self.currentThemeId
end

function Design:GetAvailableThemes()
    return Theme:GetAvailable()
end

-- A minimal stand-in for Flat, used only if the registry somehow failed to
-- populate. Kept in step with Themes/Flat.lua so the fallback is a plainer
-- version of the real thing rather than a different design.
function Design:CreateFallbackTheme()
    return {
        order = 999,
        nameKey = "THEME_FLAT",
        author = "ChatBar",
        layout = { barPadding = 0, buttonSpacing = 1, defaultShape = "square", defaultFontSize = 12 },
        bar = {
            show = true,
            showBorder = false,
            fill = { 0.055, 0.038, 0.052, 0.88 },
            accentLine = { size = 1, color = { 1, 1, 1, 0.55, accent = true }, fadeTo = 0.06 },
        },
        button = {
            fill        = { 0.62, 0.66, 0.74, 0.30, channel = true, shade = 0.045 },
            fillHover   = { 0.62, 0.66, 0.74, 0.55, channel = true, shade = 0.085 },
            fillPressed = { 0.62, 0.66, 0.74, 0.95, channel = true, shade = 0.055 },
            fillActive  = { 0.62, 0.66, 0.74, 1.00, channel = true, shade = 0.185 },
            showBorder = false,
            border = { 1, 1, 1, 0.10 },
            borderHover = { 1, 1, 1, 0.22 },
            borderActive = { 1, 1, 1, 0.95, accent = true },
            hover = { 1, 1, 1, 0.05 },
        },
        label = { source = "white", alpha = 0.62, alphaHover = 0.88, alphaActive = 1, alphaDisabled = 0.22 },
        active = { indicator = "underline", size = 1, color = { 1, 1, 1, 1, accent = true } },
        alert = { style = "plate", color = { 1, 1, 1, 1, channel = true, accent = true },
                  minAlpha = 0, maxAlpha = 0.34, period = 0.55 },
    }
end

-- True when the client actually ships the art a shape needs. Memoised on the
-- spec: the answer cannot change within a session, and this is asked on every
-- restyle.
local function ShapeAvailable(shape)
    local spec = SHAPES[shape]
    if not spec then return true end -- square, and anything unrecognised
    if spec.available ~= nil then return spec.available end

    if spec.atlas then
        spec.available = (C_Texture and C_Texture.GetAtlasInfo
            and C_Texture.GetAtlasInfo(spec.atlas) ~= nil) or false
    else
        spec.available = true
    end

    return spec.available
end

-- Whether the active theme lets the player reshape its buttons.
--
-- Shape is not always a preference. Flat is a tab strip, and a row of circles is
-- not a tab strip any more; that theme fixes its shape and the settings panel
-- greys the control out. Glass opts in, because glass is a material rather than
-- a silhouette and survives being reshaped.
function Design:AllowsShapeChoice()
    local layout = self:GetTheme().layout or {}
    return layout.shapeChoice == true
end

-- The shape a button should use.
--
-- Square unless something says otherwise: a theme that fixes its own outline,
-- or a player choice on a theme that allows one. There is no "follow the theme"
-- setting to resolve -- the dropdown offers the shapes themselves, and square is
-- simply the default value.
--
-- A shape this client cannot cut degrades to square rather than to an unmasked
-- plate pretending to be round.
function Design:GetShape()
    local layout = self:GetTheme().layout or {}
    local shape = layout.defaultShape or "square"

    if self:AllowsShapeChoice() then
        local settings = (ns.db and ns.ChatBar) and ns.ChatBar:GetSettings() or nil
        local chosen = settings and settings.buttonShape
        -- Only the offerable shapes are honoured. "rounded" is a theme's own
        -- outline rather than a menu entry, so a profile still carrying it falls
        -- through to square instead of pinning a shape the player cannot see or
        -- change.
        if chosen == "square" or chosen == "circle" then
            shape = chosen
        end
    end

    if not ShapeAvailable(shape) then
        return "square"
    end

    return shape
end

-- The shape ids the settings dropdown should offer, in display order.
--
-- "rounded" is deliberately absent: it is a theme's own choice of outline, not
-- the player's, and listing it would invite reshaping a theme into something it
-- was not designed for.
function Design:GetAvailableShapes()
    local list = { "square" }
    if ShapeAvailable("circle") then list[#list + 1] = "circle" end
    return list
end

--[[
    Shared drawing helpers
]]

-- Paint a texture as a flat colour or a vertical/horizontal gradient.
--
-- Solids go through SetGradient too, with both stops equal. SetColorTexture
-- does not clear a gradient that was set earlier, so mixing the two APIs on one
-- texture leaves a stale gradient multiplying the new colour. Using one path
-- for both cases sidesteps that entirely.
local function PaintFill(tex, fromR, fromG, fromB, fromA, toR, toG, toB, toA, orientation)
    tex:SetTexture(WHITE)
    tex:SetVertexColor(1, 1, 1, 1)
    tex:SetGradient(orientation or "VERTICAL",
        CreateColor(fromR, fromG, fromB, fromA),
        CreateColor(toR, toG, toB, toA))
end

local function PaintSolid(tex, r, g, b, a)
    PaintFill(tex, r, g, b, a, r, g, b, a)
end

--[[
    Player background overrides

    Themes decide what a surface looks like; the player gets the last word on
    its colour and how much of the world shows through it. Both overrides are
    applied at paint time rather than baked into the tokens, so switching theme
    keeps the player's choice.
]]

-- Blend `blend` of the player's background colour into a surface colour.
--
-- `blend` is how much of that colour to impose. Channel-tinted fills pass a
-- partial blend: replacing their colour outright would delete the channel
-- identity that is the whole point of those themes, so the player's colour
-- shifts the base while the channel still reads through it.
function Design:TintSurface(r, g, b, a, blend)
    local settings = (ns.db and ns.ChatBar) and ns.ChatBar:GetSettings() or nil
    if not settings then return r, g, b, a end

    local color = settings.backgroundColor
    if color then
        local k = blend or 1
        r = r + (color.r - r) * k
        g = g + (color.g - g) * k
        b = b + (color.b - b) * k
    end

    return r, g, b, a
end

-- The bar backdrop: colour blend plus the opacity slider.
--
-- Opacity applies here and nowhere else. It exists to let the world show
-- through *behind* the bar; scaling the button plates by it as well would fade
-- the channel buttons themselves, and the selection becomes unreadable at
-- exactly the low values someone reaches for when they want a subtle backdrop.
function Design:TintBarSurface(r, g, b, a)
    r, g, b, a = self:TintSurface(r, g, b, a, 1)

    local settings = (ns.db and ns.ChatBar) and ns.ChatBar:GetSettings() or nil
    local opacity = settings and settings.backgroundOpacity
    if opacity then
        a = a * opacity
    end

    return r, g, b, a
end

--[[
    Button construction
]]

-- Build the texture stack once per pooled button. Restyling reuses it; only a
-- shape change touches masks.
function Design:BuildButton(button)
    if button.cbBuilt then return button end

    -- Ring for the circular shape. A four-strip border cannot follow a curve,
    -- so round buttons get a masked full-size plate behind an inset fill.
    local outline = button:CreateTexture(nil, "BACKGROUND", nil, -8)
    outline:SetAllPoints()
    Pixel.NoSnap(outline)
    outline:Hide()
    button.cbOutline = outline

    local plate = button:CreateTexture(nil, "BACKGROUND", nil, -7)
    plate:SetAllPoints()
    Pixel.NoSnap(plate)
    button.cbPlate = plate

    -- Specular highlight across the top of the plate (Glass).
    local sheen = button:CreateTexture(nil, "BACKGROUND", nil, -6)
    Pixel.NoSnap(sheen)
    sheen:Hide()
    button.cbSheen = sheen

    -- Whole-plate alert wash.
    local alertWash = button:CreateTexture(nil, "ARTWORK", nil, 1)
    alertWash:SetAllPoints()
    Pixel.NoSnap(alertWash)
    alertWash:SetAlpha(0)
    alertWash:Hide()
    button.cbAlertWash = alertWash

    -- Accent underline marking the active channel.
    local underline = button:CreateTexture(nil, "ARTWORK", nil, 3)
    Pixel.NoSnap(underline)
    underline:Hide()
    button.cbUnderline = underline

    -- Hover wash. Its own texture rather than the HIGHLIGHT layer, because the
    -- circular shape needs it masked and HIGHLIGHT textures are awkward to mask.
    local hover = button:CreateTexture(nil, "ARTWORK", nil, 0)
    hover:SetAllPoints()
    Pixel.NoSnap(hover)
    hover:SetAlpha(0)
    button.cbHover = hover

    -- Created from a font object, not bare: a FontString must already carry a
    -- font before anything calls SetText on it or the call errors outright, and
    -- callers set the glyph independently of styling, so the font cannot wait
    -- for the first StyleLabel pass. It also gives StyleLabel a valid font to
    -- fall back to if its own SetFont is ever rejected.
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    button.cbLabel = label
    -- ChatBar.lua and the locale code still reach for button.text.
    button.text = label

    self:InstallStateScripts(button)

    button.cbBuilt = true
    return button
end

-- Hover and press tracking. Hooked rather than set, so ChatBar's own tooltip
-- scripts keep working alongside these.
function Design:InstallStateScripts(button)
    if button.cbStateHooked then return end
    button.cbStateHooked = true

    button:HookScript("OnEnter", function(self)
        self.cbHovered = true
        Design:ApplyState(self)
    end)

    button:HookScript("OnLeave", function(self)
        self.cbHovered = false
        -- A drag that ends off the button never delivers OnMouseUp, so the
        -- pressed state has to clear here too or the button stays sunk.
        self.cbPressed = false
        Design:ApplyState(self)
    end)

    button:HookScript("OnMouseDown", function(self)
        self.cbPressed = true
        Design:ApplyState(self)
    end)

    button:HookScript("OnMouseUp", function(self)
        self.cbPressed = false
        Design:ApplyState(self)
    end)
end

--[[
    Shape
]]

-- Point a mask at the art for `shape`, creating it on first use.
--
-- The wrap modes matter for the file-based mask: without CLAMPTOBLACKADDITIVE a
-- mask smaller than what it covers tiles instead of cutting, and the corners
-- come back square. SetAtlas carries the atlas's own wrap flags, so the rounded
-- shape does not repeat them.
local function EnsureMask(button, key, shape)
    local mask = button[key]
    if not mask then
        mask = button:CreateMaskTexture()
        button[key] = mask
    end

    if mask.cbShape ~= shape then
        local spec = SHAPES[shape]
        if spec.atlas then
            mask:SetAtlas(spec.atlas)
        else
            mask:SetTexture(spec.file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        end
        mask.cbShape = shape
    end

    return mask
end

local function AddMasks(mask, textures)
    for i = 1, #textures do
        local tex = textures[i]
        if tex and not tex.cbMasked then
            tex:AddMaskTexture(mask)
            tex.cbMasked = mask
        end
    end
end

local function ClearMasks(textures)
    for i = 1, #textures do
        local tex = textures[i]
        if tex and tex.cbMasked then
            tex:RemoveMaskTexture(tex.cbMasked)
            tex.cbMasked = nil
        end
    end
end

-- Apply a button shape. Idempotent: re-applying the current shape only
-- refreshes geometry, so it is safe to call from every restyle.
--
-- Square is the plain case -- no mask, and a four-strip border for the edge.
-- Circle and rounded are the same case as each other: a masked full-size plate
-- (the rim) behind a masked inset fill, because no arrangement of straight
-- strips can follow a curve. Only the mask art differs between them.
function Design:ApplyShape(button, shape)
    local inner = { button.cbPlate, button.cbSheen, button.cbAlertWash, button.cbHover }
    local outer = { button.cbOutline }

    if SHAPES[shape] then
        local outerMask = EnsureMask(button, "cbMaskOuter", shape)
        outerMask:SetAllPoints(button)
        AddMasks(outerMask, outer)

        AddMasks(EnsureMask(button, "cbMaskInner", shape), inner)

        button.cbOutline:Show()

        -- Strip borders cannot follow the curve.
        if button.chatBarBorder then
            button.chatBarBorder:Hide()
        end

        button.cbShape = shape
        button.cbRingPixels = nil -- force the geometry pass below
        self:SetRingThickness(button, 1)
        return
    end

    ClearMasks(inner)
    ClearMasks(outer)

    button.cbPlate:ClearAllPoints()
    button.cbPlate:SetAllPoints(button)
    button.cbOutline:Hide()

    button.cbShape = shape
end

-- Set the visible rim width on a masked (circle or rounded) button.
--
-- A masked shape has no strip border, so the rim is the gap between the button
-- edge and the fill: inset the fill and its mask by N pixels and the outline
-- behind them shows through by exactly that much. This is what lets the active
-- indicator thicken on those shapes the way borderActiveThickness does on
-- square ones.
function Design:SetRingThickness(button, pixels)
    if not SHAPES[button.cbShape] then return end
    if button.cbRingPixels == pixels then return end
    button.cbRingPixels = pixels

    local inset = Pixel.OnePixelFor(button) * pixels

    local mask = button.cbMaskInner
    if mask then
        mask:ClearAllPoints()
        mask:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
        mask:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
    end

    button.cbPlate:ClearAllPoints()
    button.cbPlate:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    button.cbPlate:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
end

--[[
    Styling
]]

-- Position and size the sub-textures that depend on button size or bar
-- orientation: sheen height and the active underline.
function Design:LayoutButtonParts(button, size, orientation)
    local theme = self:GetTheme()
    local btn = theme.button
    local onePixel = Pixel.OnePixelFor(button)

    -- Sheen: a band across the top of the plate.
    local sheen = button.cbSheen
    if btn.sheen then
        sheen:ClearAllPoints()
        sheen:SetPoint("TOPLEFT", button.cbPlate, "TOPLEFT", 0, 0)
        sheen:SetPoint("TOPRIGHT", button.cbPlate, "TOPRIGHT", 0, 0)
        sheen:SetHeight(size * (btn.sheen.heightRatio or 0.45))
    end

    -- Active indicator: drawn inside the button bounds, along its trailing
    -- edge. Hanging it outside would collide with the next button once the bar
    -- runs vertically, where spacing is smaller than the indicator.
    local underline = button.cbUnderline
    local activeCfg = theme.active or {}
    local thickness = onePixel * (activeCfg.size or 2)

    underline:ClearAllPoints()
    if orientation == "vertical" then
        underline:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        underline:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        underline:SetWidth(thickness)
    else
        underline:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        underline:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        underline:SetHeight(thickness)
    end
end

-- Full restyle of a button.
--   opts.size          button edge length
--   opts.channelColor  ChatTypeInfo entry for this channel
--   opts.fontSize
--   opts.textPosition  "inside" | "above"
--   opts.orientation   "horizontal" | "vertical"
--   opts.enabled
--   opts.active        this is the channel the edit box currently points at
function Design:StyleButton(button, opts)
    self:BuildButton(button)

    local theme = self:GetTheme()
    local size = opts.size or 20

    button.cbSize = size
    -- Numbered channels carry no colour of their own by design. Dropping the
    -- colour here rather than special-casing it downstream is what makes every
    -- `channel`-marked token in every theme fall back to its literal value --
    -- which is exactly the neutral plate those buttons are supposed to get.
    button.cbChannelColor = (not opts.numbered) and opts.channelColor or nil
    button.cbEnabled = opts.enabled ~= false
    button.cbActive = opts.active and true or false
    button.cbOrientation = opts.orientation or "horizontal"

    button:SetSize(size, size)

    local shape = self:GetShape()
    self:ApplyShape(button, shape)

    -- Border: created lazily, and only for square buttons. The masked shapes
    -- draw their edge as a rim instead (see SetRingThickness).
    local btn = theme.button
    if not SHAPES[shape] and btn.showBorder then
        local r, g, b, a = Theme:Resolve(btn.border, button.cbChannelColor)
        local border = Pixel.CreateBorder(button, r, g, b, a, { layer = "OVERLAY", subLayer = 6 })
        border:Show()
    elseif button.chatBarBorder then
        button.chatBarBorder:Hide()
    end

    self:LayoutButtonParts(button, size, button.cbOrientation)
    self:StyleLabel(button, opts)
    self:ApplyState(button)
end

function Design:StyleLabel(button, opts)
    local theme = self:GetTheme()
    local cfg = theme.label or {}
    local label = button.cbLabel

    local fontSize = opts.fontSize or (theme.layout and theme.layout.defaultFontSize) or 12

    -- SetFont leaves the existing font in place when it rejects the path, and
    -- BuildButton seeded a valid one, so a bad path degrades to the Blizzard
    -- face instead of leaving the string fontless.
    local fontPath = Theme:GetFontPath()
    if fontPath then
        label:SetFont(fontPath, fontSize, cfg.outline or "")
    end

    if cfg.shadow then
        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)
    else
        label:SetShadowColor(0, 0, 0, 0)
        label:SetShadowOffset(0, 0)
    end

    label:ClearAllPoints()

    if opts.textPosition == "above" then
        label:SetPoint("BOTTOM", button, "TOP", 0, 2)
        label:Show()
        return
    end

    --[[ Optical centring

        A FontString centres its *line box*, which reserves descender space
        below the baseline. These glyphs are all uppercase letters and digits,
        which never use that space, so the letter ends up sitting visibly high
        inside the plate. Nudging down by a fraction of the font size puts the
        cap height back in the middle.
    ]]
    local dy = 0

    -- Snap to the nearest pixel rather than truncating: the nudge is around one
    -- pixel at usual font sizes, and truncation would round it away to nothing
    -- for half the size range.
    local opticalRatio = cfg.opticalOffset or 0.08
    dy = dy - Pixel.Snap(fontSize * opticalRatio)

    label:SetPoint("CENTER", button, "CENTER", 0, dy)
    label:Show()
end

--[[
    Visual state machine

    Everything that changes on hover, press, activation or availability is
    resolved here from the button's recorded state, so there is exactly one
    place where a state maps to a set of colours.
]]

function Design:ApplyState(button)
    if not button.cbBuilt then return end

    local theme = self:GetTheme()
    local btn = theme.button
    local labelCfg = theme.label or {}
    local activeCfg = theme.active or {}

    local channel = button.cbChannelColor
    local enabled = button.cbEnabled ~= false
    local active = button.cbActive and enabled
    local hovered = button.cbHovered and enabled
    local pressed = button.cbPressed and enabled

    --[[ Plate fill ]]
    local fillToken = btn.fill
    if pressed then
        fillToken = btn.fillPressed or fillToken
    elseif active then
        fillToken = btn.fillActive or fillToken
    elseif hovered then
        fillToken = btn.fillHover or fillToken
    end

    local plate = button.cbPlate
    local gradient = btn.gradient

    if gradient then
        local fr, fg, fb, fa = Theme:Resolve(gradient.from, channel)
        local tr, tg, tb, ta = Theme:Resolve(gradient.to, channel)

        -- Each state names how far to lift the gradient and how much to thicken
        -- it. A theme that omits the table gets no state response at all, which
        -- is the honest failure: better a flat-looking button than one whose
        -- states were invented here.
        local states = btn.gradientStates
        local step
        if pressed then
            step = states and states.pressed
        elseif active then
            step = states and states.active
        elseif hovered then
            step = states and states.hover
        end

        if step then
            -- `lift` is a luminance multiplier, not a blend toward white. The
            -- difference matters: blending an active plate toward white washes
            -- the channel colour out to grey exactly when the design most needs
            -- it visible. Scaling brightness keeps the hue and the saturation.
            local lift = step.lift or 0
            if lift ~= 0 then
                -- The lit end takes the full lift and the dark end a little over
                -- half of it, which steepens the gradient rather than sliding
                -- the whole plate up -- an active glass button should read as
                -- *lit from above*, not as uniformly brighter.
                fr, fg, fb = Theme:ScaleLuminance(fr, fg, fb, 1 + lift * 0.55)
                tr, tg, tb = Theme:ScaleLuminance(tr, tg, tb, 1 + lift)
            end

            local da = step.alpha or 0
            fa = math.min(1, fa + da)
            ta = math.min(1, ta + da)
        end

        -- Partial blend: the channel tint is what these themes are built on, so
        -- the player's colour shifts the base rather than replacing it. The dark
        -- end takes more of it than the lit end.
        fr, fg, fb, fa = self:TintSurface(fr, fg, fb, fa, 0.75)
        tr, tg, tb, ta = self:TintSurface(tr, tg, tb, ta, 0.35)

        PaintFill(plate, fr, fg, fb, fa, tr, tg, tb, ta, gradient.orientation)
    else
        local r, g, b, a = Theme:Resolve(fillToken, channel)
        -- Same reasoning as the gradient branch: a channel-tinted fill carries
        -- the identity, so the player's background colour shifts it instead of
        -- overwriting it. An untinted fill has nothing to protect and takes the
        -- colour outright.
        local carriesChannel = fillToken and fillToken.channel and channel
        r, g, b, a = self:TintSurface(r, g, b, a, carriesChannel and 0.45 or 1)
        PaintSolid(plate, r, g, b, a)
    end

    --[[ Sheen ]]
    local sheen = button.cbSheen
    if btn.sheen then
        local fr, fg, fb, fa = Theme:Resolve(btn.sheen.from, channel)
        local tr, tg, tb, ta = Theme:Resolve(btn.sheen.to, channel)
        -- The band runs bottom-to-top within its own frame; `to` is the bright
        -- end and belongs at the top of the button.
        PaintFill(sheen, fr, fg, fb, fa, tr, tg, tb, ta, "VERTICAL")
        sheen:SetShown(enabled)
    else
        sheen:Hide()
    end

    --[[ Hover wash ]]
    local hoverTex = button.cbHover
    if btn.hover then
        local r, g, b, a = Theme:Resolve(btn.hover, channel)
        PaintSolid(hoverTex, r, g, b, a)
        hoverTex:SetAlpha(hovered and 1 or 0)
    else
        hoverTex:SetAlpha(0)
    end

    --[[ Active indicator ]]
    local indicator = activeCfg.indicator or "underline"
    -- A straight rule tucked under a curve reads as a misalignment, so any
    -- masked shape takes the rim instead of the underline.
    if SHAPES[button.cbShape] and indicator == "underline" then
        indicator = "ring"
    end

    local underline = button.cbUnderline
    if active and indicator == "underline" then
        local r, g, b, a = Theme:Resolve(activeCfg.color, channel)
        PaintSolid(underline, r, g, b, a)
        underline:Show()
    else
        underline:Hide()
    end

    --[[ Border / ring ]]
    local borderToken = btn.border
    local thickness = 1
    if active and (indicator == "ring" or btn.borderActive) then
        borderToken = btn.borderActive or borderToken
        thickness = btn.borderActiveThickness or 1
    elseif hovered then
        borderToken = btn.borderHover or borderToken
    end

    local br, bg, bb, ba = Theme:Resolve(borderToken, channel)
    if not enabled then ba = ba * 0.4 end

    if SHAPES[button.cbShape] then
        PaintSolid(button.cbOutline, br, bg, bb, ba)
        self:SetRingThickness(button, thickness)
    elseif button.chatBarBorder and btn.showBorder then
        button.chatBarBorder:SetColor(br, bg, bb, ba)
        if button.chatBarBorder.thickness ~= thickness then
            button.chatBarBorder:SetThickness(thickness)
        end
    end

    --[[ Label ]]
    local label = button.cbLabel
    local alpha = labelCfg.alpha or 0.7
    if not enabled then
        alpha = labelCfg.alphaDisabled or 0.25
    elseif active then
        alpha = labelCfg.alphaActive or 1
    elseif hovered then
        alpha = labelCfg.alphaHover or 1
    end

    local lr, lg, lb = 1, 1, 1
    if labelCfg.source == "channel" and channel then
        -- Guild green and officer green are too dark to read at small sizes;
        -- lift anything below the legibility floor.
        lr, lg, lb = Theme:Legible(channel.r, channel.g, channel.b)
    elseif labelCfg.source == "accent" then
        lr, lg, lb = Theme:GetAccent()
    end

    label:SetTextColor(lr, lg, lb, alpha)
    button.cbLabelAlpha = alpha

    -- Buttons keep full frame alpha; the disabled read comes from the token
    -- alphas above, which keeps the plate visible as a hit target.
    button:SetAlpha(1)
end

function Design:SetActive(button, active)
    if not button or button.cbActive == (active and true or false) then return end
    button.cbActive = active and true or false
    self:ApplyState(button)
end

function Design:SetEnabled(button, enabled)
    if not button then return end
    button.cbEnabled = enabled ~= false
    self:ApplyState(button)
end

function Design:SetChannelColor(button, color)
    if not button then return end
    button.cbChannelColor = color
    self:ApplyState(button)
end

-- Release a pooled button's theme-specific state. The texture stack survives;
-- only masks and animations, which a theme or shape change invalidates, go.
function Design:ReleaseButton(button)
    if not button or not button.cbBuilt then return end

    self:StopAlert(button)

    ClearMasks({ button.cbPlate, button.cbSheen, button.cbAlertWash, button.cbHover, button.cbOutline })

    button.cbShape = nil
    button.cbRingPixels = nil -- stale cache would skip the next ring geometry pass
    button.cbActive = false
    button.cbHovered = false
    button.cbPressed = false
end

--[[
    Alerts

    A looping alpha pulse on whichever element the theme nominates. No scaling,
    no additive bloom: the bar keeps its silhouette while still drawing the eye.
]]

local function AlertTarget(button, theme)
    local style = theme.alert and theme.alert.style or "plate"
    if style == "label" then
        return button.cbLabel
    end
    return button.cbAlertWash
end

function Design:StartAlert(button)
    if not button or not button.cbBuilt then return end

    local theme = self:GetTheme()
    local cfg = theme.alert or {}
    local target = AlertTarget(button, theme)
    if not target then return end

    self:StopAlert(button)

    -- The plate wash carries no colour of its own until an alert needs it.
    if target == button.cbAlertWash then
        local r, g, b = Theme:Resolve(cfg.color, button.cbChannelColor)
        PaintSolid(target, r, g, b, 1)
    end

    target:Show()

    -- An animation group belongs to the region that created it and cannot be
    -- retargeted, so groups are cached per target rather than rebuilt each time
    -- a theme change moves the alert to a different element.
    button.cbAlertAnims = button.cbAlertAnims or {}
    local anim = button.cbAlertAnims[target]
    if not anim then
        anim = target:CreateAnimationGroup()
        anim:SetLooping("BOUNCE")
        local fade = anim:CreateAnimation("Alpha")
        fade:SetOrder(1)
        fade:SetSmoothing("IN_OUT")
        anim.fade = fade
        button.cbAlertAnims[target] = anim
    end
    button.cbAlertAnim = anim

    -- The label pulses between its resting alpha and full, not from zero:
    -- a letter blinking out entirely is harder to read than one that brightens.
    local minAlpha = cfg.minAlpha or 0.15
    local maxAlpha = cfg.maxAlpha or 1
    if target == button.cbLabel then
        minAlpha = math.max(minAlpha, button.cbLabelAlpha or minAlpha)
    end

    anim.fade:SetFromAlpha(minAlpha)
    anim.fade:SetToAlpha(maxAlpha)
    anim.fade:SetDuration(cfg.period or 0.55)

    target:SetAlpha(minAlpha)
    anim:Play()

    button.cbAlerting = true
    button.isFlashing = true
end

function Design:StopAlert(button)
    if not button then return end

    if button.cbAlertAnim then
        button.cbAlertAnim:Stop()
    end

    if button.cbAlertWash then
        button.cbAlertWash:SetAlpha(0)
        button.cbAlertWash:Hide()
    end

    button.cbAlerting = false
    button.isFlashing = false

    -- Restore whatever the resting state should look like.
    if button.cbBuilt then
        if button.cbLabel then button.cbLabel:SetAlpha(1) end
        self:ApplyState(button)
    end
end

--[[
    Bar
]]

function Design:BuildBar(bar)
    if bar.cbBuilt then return bar end

    local plate = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
    plate:SetAllPoints()
    Pixel.NoSnap(plate)
    bar.cbPlate = plate

    -- The accent rule along the bar's trailing edge. Drawn on the bar rather
    -- than per button so it runs unbroken across the whole strip, including the
    -- gaps between plates -- which is what makes it read as one line under a
    -- row of tabs instead of as a mark on each tab.
    local accentLine = bar:CreateTexture(nil, "BORDER", nil, 2)
    Pixel.NoSnap(accentLine)
    accentLine:Hide()
    bar.cbAccentLine = accentLine

    bar.cbBuilt = true
    self:StyleBar(bar)
    return bar
end

function Design:StyleBar(bar)
    if not bar or not bar.cbBuilt then return end

    local theme = self:GetTheme()
    local cfg = theme.bar or {}
    local plate = bar.cbPlate

    if cfg.show == false then
        plate:Hide()
        bar.cbAccentLine:Hide()
        if bar.chatBarBorder then bar.chatBarBorder:Hide() end
        return
    end

    plate:Show()

    -- The bar backdrop carries no channel identity, so the player's colour
    -- replaces it outright.
    if cfg.gradient then
        local fr, fg, fb, fa = Theme:Resolve(cfg.gradient.from)
        local tr, tg, tb, ta = Theme:Resolve(cfg.gradient.to)
        fr, fg, fb, fa = self:TintBarSurface(fr, fg, fb, fa)
        tr, tg, tb, ta = self:TintBarSurface(tr, tg, tb, ta)
        PaintFill(plate, fr, fg, fb, fa, tr, tg, tb, ta, cfg.gradient.orientation)
    else
        local r, g, b, a = Theme:Resolve(cfg.fill)
        r, g, b, a = self:TintBarSurface(r, g, b, a)
        PaintSolid(plate, r, g, b, a)
    end

    if cfg.showBorder then
        local r, g, b, a = Theme:Resolve(cfg.border)
        local border = Pixel.CreateBorder(bar, r, g, b, a, { layer = "BORDER", subLayer = 1 })
        border:Show()
    elseif bar.chatBarBorder then
        bar.chatBarBorder:Hide()
    end

    self:StyleAccentLine(bar, cfg)
end

-- The accent rule under the bar.
--
-- It runs along the trailing edge -- the bottom of a horizontal bar, the left of
-- a vertical one -- and fades along its length rather than stopping dead, so the
-- eye reads a deliberate underline instead of a border that ran out of budget.
--
-- The fade is a gradient on a single texture, not a stack of segments: one draw
-- call, and it rescales for free when the bar grows a button.
function Design:StyleAccentLine(bar, cfg)
    local line = bar.cbAccentLine
    local accentCfg = cfg.accentLine

    if not accentCfg then
        line:Hide()
        return
    end

    local settings = (ns.db and ns.ChatBar) and ns.ChatBar:GetSettings() or nil
    local vertical = settings and settings.orientation == "vertical"
    local thickness = Pixel.OnePixelFor(bar) * (accentCfg.size or 1)

    line:ClearAllPoints()
    if vertical then
        line:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        line:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        line:SetWidth(thickness)
    else
        line:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        line:SetHeight(thickness)
    end

    local r, g, b, a = Theme:Resolve(accentCfg.color)
    local fadeTo = accentCfg.fadeTo or a

    -- The rule is part of the bar's backdrop, so the background opacity slider
    -- takes it down with everything else. Its colour is not blended toward the
    -- player's background colour, though: it is the accent, and an accent that
    -- can be recoloured into the plate behind it has stopped being one.
    local opacity = settings and settings.backgroundOpacity
    if opacity then
        a, fadeTo = a * opacity, fadeTo * opacity
    end

    -- Gradients run min -> max: left to right when HORIZONTAL, bottom to top
    -- when VERTICAL. The bright end belongs at the bar's leading edge, which is
    -- the left of a horizontal bar and the top of a vertical one -- so the
    -- vertical case runs faded -> bright and the horizontal case bright -> faded.
    if vertical then
        PaintFill(line, r, g, b, fadeTo, r, g, b, a, "VERTICAL")
    else
        PaintFill(line, r, g, b, a, r, g, b, fadeTo, "HORIZONTAL")
    end

    line:Show()
end

--[[
    Layout metrics, read by ChatBar when it positions buttons
]]

function Design:GetPadding()
    local theme = self:GetTheme()
    return (theme.layout and theme.layout.barPadding) or 4
end

function Design:GetSpacing()
    local theme = self:GetTheme()
    return (theme.layout and theme.layout.buttonSpacing) or 2
end

function Design:GetDefaultFontSize()
    local theme = self:GetTheme()
    return (theme.layout and theme.layout.defaultFontSize) or 12
end

--[[
    Live re-theming
]]

Theme:OnChanged(function()
    if ns.ChatBar and ns.ChatBar.Refresh then
        ns.ChatBar:Refresh()
    end
end)
