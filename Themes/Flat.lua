-- ChatBar theme: Flat
--
-- Modelled on the chat tab strip: a dark plate, the active channel filled in,
-- the rest sitting back at low alpha, and one accent rule drawn along the
-- bottom of the whole bar.
--
-- Channel identity lives in the plate fill rather than in a separate stripe or
-- in the label. Every fill is the channel's own colour rescaled to a fixed
-- perceptual luminance (`shade`), so a row of eight channels reads as eight
-- hues at one brightness instead of the glare-and-mud that ChatTypeInfo's raw
-- palette produces -- SAY is pure white in that table, GUILD is nearly black.
--
-- Numbered channels deliberately carry no colour. They arrive with no channel
-- colour at all, which drops each token to its literal value: the cool grey
-- written into every fill below. That is why the literals are grey and not the
-- near-black of the bar -- they are the numbered-channel look, not a fallback
-- nobody sees.

local addonName, ns = ...

ns.ThemeRegistry = ns.ThemeRegistry or {}

ns.ThemeRegistry["Flat"] = {
    order = 1,
    nameKey = "THEME_FLAT",
    descKey = "THEME_FLAT_DESC",
    author = "ChatBar",

    layout = {
        barPadding = 0,
        buttonSpacing = 1,
        -- Square, and not negotiable. This theme is a tab strip: the plates butt
        -- up against each other under one continuous accent rule, and a row of
        -- circles has neither the shared edge nor the rule to sit under.
        defaultShape = "square",
        shapeChoice = false,
        defaultFontSize = 12,
    },

    bar = {
        show = true,
        showBorder = false,
        fill = { 0.055, 0.038, 0.052, 0.88 },

        -- The rule under the strip. Brightest at the leading edge and fading
        -- along the bar, so it reads as a deliberate underline rather than as a
        -- border someone forgot to finish.
        accentLine = {
            size = 1,
            color = { 1, 1, 1, 0.55, accent = true },
            fadeTo = 0.06,
        },
    },

    button = {
        -- One hue, four weights. Alpha carries most of the state change and
        -- `shade` carries the rest, which keeps the row calm: nothing moves,
        -- nothing changes colour, one plate just fills in.
        fill        = { 0.62, 0.66, 0.74, 0.34, channel = true, shade = 0.050 },
        fillHover   = { 0.62, 0.66, 0.74, 0.62, channel = true, shade = 0.120 },
        fillPressed = { 0.62, 0.66, 0.74, 0.95, channel = true, shade = 0.070 },
        fillActive  = { 0.62, 0.66, 0.74, 1.00, channel = true, shade = 0.300 },

        -- No border at all. The gap between plates is the only separation this
        -- design wants, and a hairline around every plate at this size reads as
        -- noise long before it reads as structure. With the shape fixed to
        -- square there is no rim case to keep these tokens alive for.
        showBorder = false,

        hover = { 1, 1, 1, 0.05 },
    },

    label = {
        source = "white",
        alpha = 0.62,
        alphaHover = 0.88,
        alphaActive = 1.00,
        alphaDisabled = 0.22,
        shadow = false,
        outline = "",
    },

    active = {
        indicator = "underline",
        size = 1,
        color = { 1, 1, 1, 1, accent = true },
    },

    alert = {
        -- The plate itself breathes. With identity already in the fill there is
        -- no stripe to pulse, and washing the plate keeps the bar's silhouette
        -- while still catching the eye. `accent` is the fallback the numbered
        -- channels take, since they have no colour of their own.
        style = "plate",
        color = { 1, 1, 1, 1, channel = true, accent = true },
        minAlpha = 0.00,
        maxAlpha = 0.34,
        period = 0.55,
    },
}
