-- ChatBar: Theme tokens and accent resolution
--
-- Themes are pure Lua token sets -- no .tga files. Every surface is drawn with
-- SetColorTexture or SetGradient, which means the look is resolution
-- independent, hot-swappable, and costs nothing to ship.
--
-- A theme never names a literal accent colour. It asks for `accent` and this
-- module resolves it from the player's choice (class colour by default), so a
-- single set of themes covers every accent without duplicating tokens.

local addonName, ns = ...

local Theme = {}
ns.Theme = Theme

-- Populated by the files in Themes/, which load before this one's consumers.
ns.ThemeRegistry = ns.ThemeRegistry or {}

local min, max = math.min, math.max

-- The face ChatBar bundles: Expressway Free by Ray Larabie, freeware, covering
-- Latin, Latin-1 and Cyrillic. Referenced by path because it is our own media --
-- there is no font object to go through, and no locale variant to pick.
local EXPRESSWAY = "Interface\\AddOns\\ChatBar\\Media\\Expressway.ttf"

-- Locales the bundled face cannot draw.
--
-- Checked against its actual cmap rather than assumed: it maps 442 codepoints
-- covering Latin, Latin-1 and the complete Cyrillic alphabet including the Yo
-- pair, and nothing beyond that. So ruRU renders natively and only the CJK
-- locales, which need thousands of glyphs no Latin-family face carries, fall
-- back to the client's own font.
local UNSUPPORTED_LOCALES = {
    koKR = true,
    zhCN = true,
    zhTW = true,
}

--[[
    Accent colours
]]

-- Preset accents. `class` and `custom` resolve at runtime and are absent here.
local ACCENT_PRESETS = {
    teal   = { 0.047, 0.824, 0.616 }, -- #0CD29D
    azure  = { 0.247, 0.655, 1.000 }, -- #3FA7FF
    ember  = { 1.000, 0.353, 0.122 }, -- #FF5A1F
    violet = { 0.471, 0.255, 0.784 }, -- #7841C8
    gold   = { 1.000, 0.776, 0.267 }, -- #FFC644
    mono   = { 1.000, 1.000, 1.000 },
}

-- Order shown in the settings dropdown.
Theme.ACCENT_ORDER = { "class", "teal", "azure", "ember", "violet", "gold", "mono", "custom" }

Theme.ACCENT_PRESETS = ACCENT_PRESETS

local DEFAULT_ACCENT = ACCENT_PRESETS.teal

-- Cached resolved accent, invalidated by Theme:Invalidate().
local resolvedAccent = nil

local function ResolvePlayerClassColor()
    local _, classFilename = UnitClass("player")
    if not classFilename then return nil end

    -- C_ClassColor is the modern accessor; RAID_CLASS_COLORS remains as a
    -- fallback for the rare case it is unavailable this early in login.
    if C_ClassColor and C_ClassColor.GetClassColor then
        local color = C_ClassColor.GetClassColor(classFilename)
        if color then return { color.r, color.g, color.b } end
    end

    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
    if color then return { color.r, color.g, color.b } end

    return nil
end

-- r, g, b of the accent the player has chosen.
function Theme:GetAccent()
    if resolvedAccent then
        return resolvedAccent[1], resolvedAccent[2], resolvedAccent[3]
    end

    -- ns.db only exists once SavedVariables have loaded; anything asking for an
    -- accent before then gets the default rather than a nil index.
    local settings = (ns.db and ns.ChatBar) and ns.ChatBar:GetSettings() or nil
    local mode = settings and settings.accent or "class"
    local color

    if mode == "class" then
        color = ResolvePlayerClassColor()
    elseif mode == "custom" then
        local custom = settings and settings.accentColor
        if custom then color = { custom.r, custom.g, custom.b } end
    else
        color = ACCENT_PRESETS[mode]
    end

    resolvedAccent = color or DEFAULT_ACCENT
    return resolvedAccent[1], resolvedAccent[2], resolvedAccent[3]
end

-- Drop the cached accent so the next read re-resolves it. Call after any
-- settings change that could affect the accent.
function Theme:Invalidate()
    resolvedAccent = nil
    self.fontPathCache = nil
end

-- Whether an accent id is offerable. "class" and "custom" resolve at runtime;
-- everything else must name a preset.
function Theme:IsAccentAvailable(id)
    if id == "class" or id == "custom" then return true end
    return ACCENT_PRESETS[id] ~= nil
end

-- The accent ids the settings dropdown should offer, in display order.
function Theme:GetAccentChoices()
    local list = {}
    for i = 1, #self.ACCENT_ORDER do
        local id = self.ACCENT_ORDER[i]
        if self:IsAccentAvailable(id) then
            list[#list + 1] = id
        end
    end
    return list
end

--[[
    Colour helpers

    Token colours are plain { r, g, b, a } arrays rather than ColorMixin: they
    are read on every hover and a table lookup beats a method call. CreateColor
    is used only where the API demands it (SetGradient).
]]

-- Resolve a token colour to r, g, b, a.
--
-- A token is { r, g, b, a } plus optional markers:
--   accent = true    substitute the live accent colour
--   channel = true   substitute the channel colour passed in
--   shade   = 0..1   scale the result to this perceptual luminance
--   darken  = 0..1   scale the result toward black
--   lighten = 0..1   blend the result toward white
--
-- The literal r, g, b stay meaningful under a marker: they are the fallback
-- when the substitution has nothing to offer (a channel with no ChatTypeInfo
-- entry, for instance), so a theme never has to declare the same colour twice.
--
-- `channel` is tried before `accent`, which makes a token carrying both mean
-- "this channel's colour, or the accent if it has none". Numbered channels are
-- exactly that case: they deliberately arrive with no colour of their own, and
-- an alert on one should still pulse in a colour that belongs to the theme.
function Theme:Resolve(token, channelColor, alphaOverride)
    if not token then return 1, 1, 1, 1 end

    local r, g, b, a = token[1], token[2], token[3], token[4] or 1

    if token.channel and channelColor then
        r, g, b = channelColor.r, channelColor.g, channelColor.b
    elseif token.accent then
        r, g, b = self:GetAccent()
    end

    if token.shade then
        r, g, b = self:ToLuminance(r, g, b, token.shade)
    end
    if token.darken then
        r, g, b = self:Darken(r, g, b, token.darken)
    end
    if token.lighten then
        r, g, b = self:Lighten(r, g, b, token.lighten)
    end

    return r, g, b, alphaOverride or a
end

-- Back-compat alias for call sites that have no channel colour to offer.
function Theme:Unpack(token, alphaOverride)
    return self:Resolve(token, nil, alphaOverride)
end

-- Blend `amount` of white into a colour. Used to lift channel colours that are
-- too dark to read as a label (officer green, guild green).
function Theme:Lighten(r, g, b, amount)
    return r + (1 - r) * amount,
           g + (1 - g) * amount,
           b + (1 - b) * amount
end

-- Scale a colour toward black.
function Theme:Darken(r, g, b, amount)
    local k = 1 - amount
    return r * k, g * k, b * k
end

-- Rescale a colour to a target perceptual luminance, keeping its hue.
--
-- This is what makes "every channel gets its own colour" survive contact with
-- ChatTypeInfo, whose palette is wildly uneven: SAY is pure white, GUILD is a
-- dark green, YELL is a saturated red. Darkening them all by the same fraction
-- leaves a row where one plate glares and the next is invisible. Normalising to
-- a luminance instead means every plate carries the same visual weight and only
-- the hue differs -- which is the whole point of colouring them.
--
-- Scaling rather than blending toward grey is deliberate: it keeps saturation,
-- so the hue is still readable at the very low luminances a dark UI wants.
function Theme:ToLuminance(r, g, b, target)
    local lum = self:Luminance(r, g, b)
    -- A colour with no luminance has no hue to preserve; lift it to the target
    -- as a neutral rather than dividing by zero.
    if lum <= 0.0001 then return target, target, target end

    local k = target / lum
    -- A scale that pushes any channel past 1 would clip and skew the hue, so
    -- cap the factor at whatever keeps the brightest channel inside gamut.
    local peak = max(r, g, b)
    if peak * k > 1 then k = 1 / max(peak, 0.0001) end

    return r * k, g * k, b * k
end

-- Multiply a colour's luminance, keeping its hue. The brightness counterpart to
-- ToLuminance: use it when a state should make a surface lighter or darker
-- *without* changing what colour it is.
--
-- This is why button states do not simply blend toward white. Blending
-- desaturates, and on a plate whose entire job is to say "this is the guild
-- channel", a lit state that fades the green out has broken the thing it was
-- meant to emphasise.
function Theme:ScaleLuminance(r, g, b, factor)
    return self:ToLuminance(r, g, b, self:Luminance(r, g, b) * factor)
end

-- Perceptual luminance (Rec. 709). Used to decide whether a channel colour
-- needs lifting before it is used as text.
function Theme:Luminance(r, g, b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Return a channel colour guaranteed legible against a dark plate.
function Theme:Legible(r, g, b, floorLuminance)
    local target = floorLuminance or 0.45
    local lum = self:Luminance(r, g, b)
    if lum >= target then return r, g, b end
    -- Lift toward white by however far short of the target we are, capped so a
    -- very dark channel colour brightens without washing out to plain white and
    -- losing the identity the colour was carrying in the first place.
    local amount = min(0.7, (target - lum) / max(target, 0.001))
    return self:Lighten(r, g, b, amount)
end

-- ColorMixin for the gradient API, which has required it since 10.0.
function Theme:Color(token, channelColor, alphaOverride)
    local r, g, b, a = self:Resolve(token, channelColor, alphaOverride)
    return CreateColor(r, g, b, a)
end

--[[
    Fonts
]]

-- Two faces, and no more.
--
-- "default" goes through a Blizzard font *object* rather than a file path.
-- Blizzard points each object at a different file per locale, so a hardcoded
-- "Fonts\\FRIZQT__.TTF" renders nothing in ruRU or koKR while the object always
-- resolves to whatever face that locale actually ships. This choice is correct
-- in every language by construction.
--
-- "expressway" is the file ChatBar bundles: Expressway Free by Ray Larabie,
-- which covers Latin, Latin-1 and Cyrillic. In a locale it cannot draw -- the
-- CJK ones -- it resolves to the default face instead. A row of empty boxes is
-- not a font choice; falling back is the only honest behaviour, and it is why
-- the choice stays listed everywhere rather than being silently broken.
Theme.FONT_CHOICES = {
    { id = "default",    nameKey = "FONT_DEFAULT",    object = "GameFontNormal" },
    { id = "expressway", nameKey = "FONT_EXPRESSWAY", file = EXPRESSWAY, limitedGlyphs = true },
}

local FONT_BY_ID = {}
for _, choice in ipairs(Theme.FONT_CHOICES) do
    FONT_BY_ID[choice.id] = choice
end

function Theme:GetFontChoice(id)
    return FONT_BY_ID[id]
end

-- Both choices are always offered. The Latin-only face is not hidden in a
-- locale it cannot render -- it degrades there instead -- so the settings panel
-- looks the same everywhere.
function Theme:GetFontChoices()
    return self.FONT_CHOICES
end

function Theme:IsFontAvailable(id)
    return FONT_BY_ID[id] ~= nil
end

-- The font id in effect: the player's pick, or the client's own face.
function Theme:GetFontId()
    local settings = (ns.db and ns.ChatBar) and ns.ChatBar:GetSettings() or nil
    local fontId = settings and settings.font
    return FONT_BY_ID[fontId] and fontId or "default"
end

-- Whether the bundled face can draw this client's language at all.
local function LocaleIsSupported()
    return not UNSUPPORTED_LOCALES[GetLocale()]
end

-- Resolve a font id to a file path, or nil when nothing backs it.
local function ResolvePath(fontId)
    local choice = FONT_BY_ID[fontId]
    if not choice then return nil end

    if choice.file then
        if choice.limitedGlyphs and not LocaleIsSupported() then return nil end
        return choice.file
    end

    local object = choice.object and _G[choice.object]
    return object and object.GetFont and object:GetFont() or nil
end

-- Resolve a font id to a usable file path, falling back through the default
-- face and finally STANDARD_TEXT_FONT.
function Theme:GetFontPath(fontId)
    fontId = fontId or self:GetFontId()

    local cached = self.fontPathCache and self.fontPathCache[fontId]
    if cached then return cached end

    local path = ResolvePath(fontId) or ResolvePath("default")

    if not path then
        path = GameFontNormal and GameFontNormal:GetFont() or STANDARD_TEXT_FONT
    end

    -- Never cache a nil: font objects can be queried before the client has
    -- finished setting them up, and caching that answer would make a transient
    -- miss permanent for the rest of the session.
    if path then
        self.fontPathCache = self.fontPathCache or {}
        self.fontPathCache[fontId] = path
    end

    return path
end

--[[
    Theme lookup
]]

function Theme:Get(id)
    return ns.ThemeRegistry[id]
end

-- Sorted list of { id, name, description } for the settings dropdown.
function Theme:GetAvailable()
    local L = ns.L
    local list = {}

    for id, theme in pairs(ns.ThemeRegistry) do
        list[#list + 1] = {
            id = id,
            order = theme.order or 100,
            name = (theme.nameKey and L[theme.nameKey]) or id,
            description = (theme.descKey and L[theme.descKey]) or "",
        }
    end

    table.sort(list, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.name < b.name
    end)

    return list
end

--[[
    Change notification

    Design.lua and Config.lua subscribe so a live accent or theme change repaints
    everything already on screen without a reload.
]]

local listeners = {}

function Theme:OnChanged(fn)
    listeners[#listeners + 1] = fn
end

function Theme:NotifyChanged(reason)
    self:Invalidate()
    for i = 1, #listeners do
        listeners[i](reason)
    end
end

-- Class colour is not reliable until the player entity exists.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function()
    Theme:Invalidate()
end)
