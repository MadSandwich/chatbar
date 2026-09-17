-- ChatBar theme: Glass
--
-- The same design as Flat -- channel colour in the plate, accent rule under the
-- bar, the active channel filled in -- rendered as glass instead of paint.
--
-- Three things make the difference, and none of them is the outline. The fill is
-- a vertical gradient, dark at the bottom and lit at the top, so the surface has
-- a direction. A sheen sits across the upper third, which is what the eye
-- actually reads as "this is glass" rather than "this is a gradient". And every
-- plate carries a hairline rim that lifts to the accent when its channel is
-- active, the way light catches the edge of a real pane.
--
-- The plates are square. Glass is a material, not a silhouette: keeping the
-- same rectangle as Flat is what makes the two themes read as one design in two
-- finishes rather than as two unrelated bars.
--
-- Both ends of every gradient are the channel's own colour normalised to a
-- luminance (`shade`), exactly as in Flat: the gradient is a lighting model, not
-- a second colour. Numbered channels drop to the grey literals and come out as
-- clear glass.

local addonName, ns = ...

ns.ThemeRegistry = ns.ThemeRegistry or {}

ns.ThemeRegistry["Glass"] = {
    order = 2,
    nameKey = "THEME_GLASS",
    descKey = "THEME_GLASS_DESC",
    author = "ChatBar",

    layout = {
        -- Wider than Flat on purpose. Flat butts its plates together into one
        -- continuous strip; these are separate panes, and each needs a margin
        -- of its own for the rim to read as an edge rather than as a seam.
        barPadding = 3,
        buttonSpacing = 3,
        defaultShape = "square",
        -- Unlike Flat, this theme's look survives being reshaped -- a round
        -- pane is still glass -- so the settings panel keeps its shape control
        -- live here.
        shapeChoice = true,
        defaultFontSize = 12,
    },

    bar = {
        show = true,
        showBorder = false,
        fill = { 0.045, 0.032, 0.045, 0.82 },
        gradient = {
            -- VERTICAL gradients run min -> max bottom to top.
            orientation = "VERTICAL",
            from = { 0.030, 0.022, 0.032, 0.90 },
            to   = { 0.070, 0.052, 0.072, 0.68 },
        },

        accentLine = {
            size = 1,
            color = { 1, 1, 1, 0.55, accent = true },
            fadeTo = 0.06,
        },
    },

    button = {
        -- Solid fallbacks. Only reached if the gradient is ever switched off;
        -- the gradient below is what this theme actually draws.
        fill        = { 0.62, 0.66, 0.74, 0.34, channel = true, shade = 0.055 },
        fillHover   = { 0.62, 0.66, 0.74, 0.58, channel = true, shade = 0.095 },
        fillPressed = { 0.62, 0.66, 0.74, 0.95, channel = true, shade = 0.060 },
        fillActive  = { 0.62, 0.66, 0.74, 1.00, channel = true, shade = 0.190 },

        -- The rim is this theme's whole edge treatment: faint at rest,
        -- accent-lit when the channel is active. On the square shape it is the
        -- pixel-snapped strip border; pick the round shape and the same tokens
        -- drive a masked ring instead, because no arrangement of straight
        -- strips can follow a curve.
        showBorder   = true,
        border       = { 1, 1, 1, 0.13 },
        borderHover  = { 1, 1, 1, 0.28 },
        borderActive = { 1, 1, 1, 0.95, accent = true },
        borderActiveThickness = 1,

        hover = { 1, 1, 1, 0.07 },

        gradient = {
            orientation = "VERTICAL",
            -- Bottom: the channel colour sunk almost to black.
            from = { 0.62, 0.66, 0.74, 0.34, channel = true, shade = 0.030 },
            -- Top: the same colour lit, held back so white text still reads.
            to   = { 0.62, 0.66, 0.74, 0.50, channel = true, shade = 0.130 },
        },

        -- What each state does to that gradient. `lift` multiplies luminance --
        -- hue and saturation are untouched, so a lit plate is a brighter version
        -- of the same colour rather than a paler one. `alpha` thickens the
        -- glass. The active step is large on purpose: "filled in" has to be
        -- obvious at a glance across a row of eight plates.
        gradientStates = {
            hover   = { lift = 0.55, alpha = 0.14 },
            active  = { lift = 1.35, alpha = 0.48 },
            pressed = { lift = -0.40, alpha = 0.34 },
        },

        -- Specular highlight across the top of the plate. Barely there by
        -- design: at 20 pixels tall anything stronger stops looking like light
        -- on a surface and starts looking like a second plate.
        sheen = {
            heightRatio = 0.42,
            from = { 1, 1, 1, 0.00 },
            to   = { 1, 1, 1, 0.11 },
        },
    },

    label = {
        source = "white",
        alpha = 0.68,
        alphaHover = 0.92,
        alphaActive = 1.00,
        alphaDisabled = 0.24,
        -- Glass sits over a lit gradient rather than a flat plate, so the label
        -- needs the shadow to hold its edge against the bright top third.
        shadow = true,
        outline = "",
    },

    active = {
        -- The rim carries the active state here rather than an underline. Flat
        -- can underline because its plates share one continuous baseline; these
        -- panes are separate, and a rule under just one of them would read as a
        -- fragment of a line that is missing everywhere else.
        indicator = "ring",
        size = 1,
        color = { 1, 1, 1, 1, accent = true },
    },

    alert = {
        style = "plate",
        color = { 1, 1, 1, 1, channel = true, accent = true },
        minAlpha = 0.00,
        maxAlpha = 0.30,
        period = 0.55,
    },
}
