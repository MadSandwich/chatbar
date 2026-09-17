-- ChatBar: Pixel-perfect geometry primitives
--
-- WoW lays frames out in a virtual 768-unit-tall coordinate space. A "1 pixel"
-- border is therefore only one physical pixel when it measures 768/screenHeight
-- units at scale 1.0 -- at any other scale it blurs across two rows, or rounds
-- away to nothing. Everything in this file exists to keep our 1px edges crisp
-- at every resolution and UI scale.

local addonName, ns = ...

local Pixel = {}
ns.Pixel = Pixel

local GetPhysicalScreenSize = GetPhysicalScreenSize
local floor, ceil, abs = math.floor, math.ceil, math.abs

-- Live borders, re-snapped whenever the pixel grid moves. Weak keys so a border
-- on a garbage-collected frame does not keep that frame alive.
local liveBorders = setmetatable({}, { __mode = "k" })

--[[
    Core grid values
]]

-- perfect = one physical pixel expressed in WoW's 768-based units at scale 1.0.
-- Guarded against GetPhysicalScreenSize() reporting 0/nil mid display-mode
-- change: 768/0 is infinite and would poison every size we derive from it.
function Pixel.RefreshPhysical()
    local w, h = GetPhysicalScreenSize()
    if h and h > 0 then
        Pixel.physicalWidth, Pixel.physicalHeight = w, h
    elseif not Pixel.physicalHeight then
        Pixel.physicalWidth, Pixel.physicalHeight = 1920, 1080
    end
    Pixel.perfect = 768 / Pixel.physicalHeight
end

Pixel.RefreshPhysical()

-- mult = one physical pixel at the current UIParent scale.
function Pixel.UpdateMult()
    Pixel.RefreshPhysical()
    Pixel.mult = Pixel.perfect / (UIParent and UIParent:GetScale() or 1)
end

Pixel.UpdateMult()

-- Snap a length or offset onto the physical pixel grid, truncating toward zero.
-- The 0.001px epsilon absorbs float dust: a value sitting exactly on a grid
-- boundary can land a hair below it and lose a whole pixel to floor().
function Pixel.Scale(value)
    if value == 0 then return 0 end
    local m = Pixel.mult
    if m == 1 then return value end
    local pixels = value / m
    pixels = value > 0 and floor(pixels + 0.001) or ceil(pixels - 0.001)
    return pixels * m
end

-- Snap to the *nearest* pixel rather than truncating. Use for saved positions,
-- where drift across reloads matters more than never overshooting.
function Pixel.Snap(value)
    if value == 0 then return 0 end
    local m = Pixel.mult
    local result = floor(value / m + 0.5) * m
    local rounded = floor(result + 0.5)
    if abs(result - rounded) < 0.001 then result = rounded end
    return result
end

-- One physical pixel expressed in the local coordinate space of `frame`.
-- Textures parented to a frame inherit its effective scale, so a strip that
-- should measure N physical pixels must be N * this many local units.
function Pixel.OnePixelFor(frame)
    local es = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    if es <= 0 then es = 1 end
    return Pixel.perfect / es
end

--[[
    Geometry helpers -- drop-in wrappers that snap their arguments
]]

function Pixel.Size(frame, w, h)
    frame:SetSize(Pixel.Scale(w), Pixel.Scale(h or w))
end

function Pixel.Point(obj, point, relTo, relPoint, x, y)
    if type(x) == "number" then x = Pixel.Scale(x) end
    if type(y) == "number" then y = Pixel.Scale(y) end
    obj:SetPoint(point, relTo, relPoint, x, y)
end

-- Turn off WoW's own texel snapping. Our 1px strips must never round to zero
-- and vanish on one side of a frame at fractional scales.
function Pixel.NoSnap(obj)
    if obj.SetSnapToPixelGrid then
        obj:SetSnapToPixelGrid(false)
        obj:SetTexelSnappingBias(0)
    end
end

-- Re-anchor a frame onto the pixel grid, preserving where it currently sits.
--
-- Snapping a frame's *internal* layout is not enough. Anchoring to another frame
-- inherits that frame's own fractional position, and every child then renders
-- half a pixel off. Small text is where it shows worst: it goes soft and loses
-- contrast, which reads as a washed-out look rather than as blur.
--
-- Returns false when the frame has no resolved rect yet (early in login), so the
-- caller can retry.
function Pixel.SnapFrame(frame)
    if not frame then return false end

    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if not left or not bottom then return false end

    -- GetLeft/GetBottom report in the frame's own coordinate space; convert to
    -- UIParent's before re-anchoring there.
    local scale = frame:GetEffectiveScale()
    local parentScale = UIParent and UIParent:GetEffectiveScale()
    if not scale or scale <= 0 or not parentScale or parentScale <= 0 then
        return false
    end

    local ratio = scale / parentScale
    left, bottom = left * ratio, bottom * ratio

    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", Pixel.Snap(left), Pixel.Snap(bottom))
    return true
end

-- Anchor `obj` inset from `anchor` by a snapped margin on all four sides.
function Pixel.Inset(obj, anchor, inset)
    local i = Pixel.Scale(inset or 1)
    obj:ClearAllPoints()
    Pixel.NoSnap(obj)
    obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", i, -i)
    obj:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -i, i)
end

--[[
    Border primitive

    Four solid strips rather than a BackdropTemplate NineSlice: NineSlice needs a
    matching corner texture to look right at 1px, and the backdrop system rounds
    its edge size onto the virtual grid rather than the physical one. Four
    WHITE8X8 strips give us exact control over both.
]]

local WHITE = "Interface\\Buttons\\WHITE8X8"

local BorderMixin = {}

function BorderMixin:SetColor(r, g, b, a)
    a = a or 1
    local c = self.color
    -- Mutated in place rather than replaced: this runs on every hover, and a
    -- fresh {r,g,b,a} table per call is pure garbage.
    if c[1] == r and c[2] == g and c[3] == b and c[4] == a then return end
    c[1], c[2], c[3], c[4] = r, g, b, a
    self.top:SetColorTexture(r, g, b, a)
    self.bottom:SetColorTexture(r, g, b, a)
    self.left:SetColorTexture(r, g, b, a)
    self.right:SetColorTexture(r, g, b, a)
end

function BorderMixin:GetColor()
    local c = self.color
    return c[1], c[2], c[3], c[4]
end

function BorderMixin:SetThickness(pixels)
    self.thickness = pixels or 1
    self:Refresh()
end

-- Re-anchor the strips against the current pixel grid. Cheap enough to call on
-- any scale or resize change.
function BorderMixin:Refresh()
    local frame = self.owner
    if not frame then return end

    local t = Pixel.OnePixelFor(frame) * (self.thickness or 1)
    local top, bottom, left, right = self.top, self.bottom, self.left, self.right

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(t)

    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(t)

    -- Verticals stop short of the horizontals so corners are not double-drawn
    -- (visible as darker corner dots once border alpha drops below 1).
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -t)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, t)
    left:SetWidth(t)

    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -t)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, t)
    right:SetWidth(t)
end

function BorderMixin:SetShown(shown)
    self.container:SetShown(shown and true or false)
end

function BorderMixin:Show() self.container:Show() end
function BorderMixin:Hide() self.container:Hide() end

-- Create (or recolor the existing) 1px border on `frame`.
--   opts.thickness  physical pixels, default 1
--   opts.layer      draw layer for the strips, default "OVERLAY"
--   opts.subLayer   sub-level within that layer, default 7
function Pixel.CreateBorder(frame, r, g, b, a, opts)
    if frame.chatBarBorder then
        frame.chatBarBorder:SetColor(r or 0, g or 0, b or 0, a or 1)
        return frame.chatBarBorder
    end

    opts = opts or {}

    local container = CreateFrame("Frame", nil, frame)
    container:SetAllPoints(frame)
    container:SetFrameLevel(frame:GetFrameLevel() + 1)
    container:EnableMouse(false)

    local border = CreateFromMixins(BorderMixin)
    border.owner = frame
    border.container = container
    border.thickness = opts.thickness or 1
    border.color = { r or 0, g or 0, b or 0, a or 1 }

    local layer, subLayer = opts.layer or "OVERLAY", opts.subLayer or 7
    local sides = { "top", "bottom", "left", "right" }
    for i = 1, #sides do
        local tex = container:CreateTexture(nil, layer, nil, subLayer)
        tex:SetTexture(WHITE)
        Pixel.NoSnap(tex)
        border[sides[i]] = tex
    end

    -- color table already holds the target values, so force the first write
    -- through instead of letting SetColor short-circuit on an equal compare.
    local cr, cg, cb, ca = border.color[1], border.color[2], border.color[3], border.color[4]
    border.color[1] = nil
    border:SetColor(cr, cg, cb, ca)
    border:Refresh()

    -- Effective scale is not final until the frame has been laid out once, so
    -- re-snap on the next frame. Single-shot: the script clears itself.
    container:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        border:Refresh()
    end)

    frame.chatBarBorder = border
    liveBorders[border] = true
    return border
end

-- Re-snap every live border. Called after the grid moves.
function Pixel.RefreshAllBorders()
    for border in pairs(liveBorders) do
        border:Refresh()
    end
end

--[[
    Grid change tracking
]]

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
watcher:RegisterEvent("UI_SCALE_CHANGED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function()
    Pixel.UpdateMult()
    Pixel.RefreshAllBorders()
end)
