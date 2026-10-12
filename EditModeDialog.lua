-- ChatBar: Edit Mode settings dialog
--
-- Opens when the bar is selected in Edit Mode, in place of the dialog Blizzard
-- shows for its own frames. It is built from the same shared templates, so it
-- looks the same, but not from Blizzard's Edit Mode setting widgets: those
-- send every change to EditModeSystemSettingsDialog, which writes it into the
-- Edit Mode layout of a registered frame.
--
-- A change applies and saves at once, like the bar's position; there is no
-- revert step. Built the first time it opens, so it costs nothing for anyone
-- who never selects the bar.

local addonName, ns = ...

local Dialog = {}
ns.EditModeDialog = Dialog

-- Blizzard's own dialog metrics (EditModeDialogs.xml, EditModeTemplates.xml)
local PADDING = 20
local TITLE_TOP = 15
local SECTION_GAP = 12
local ROW_HEIGHT = 32
local ROW_SPACING = 2
local LABEL_MIN_WIDTH = 100
local LABEL_GAP = 5
local DROPDOWN_WIDTH = 225
local SLIDER_WIDTH = 200
local SLIDER_VALUE_WIDTH = 38 -- the value the slider prints to its right
local BUTTON_HEIGHT = 28

local frame
local rows = {}
local resetButton

local function Settings()
    return ns.ChatBar:GetSettings()
end

-- The settings panel's labels end in a colon; Blizzard's Edit Mode labels don't.
local function StripColon(text)
    return (text:gsub("%s*:%s*$", ""))
end

local function CreateRow(labelText)
    local row = CreateFrame("Frame", nil, frame)
    row:SetHeight(ROW_HEIGHT)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    label:SetJustifyH("LEFT")
    label:SetPoint("LEFT")
    label:SetText(StripColon(labelText))

    rows[#rows + 1] = { frame = row, label = label }
    return rows[#rows]
end

local function AddDropdown(labelText, options, get, set)
    local row = CreateRow(labelText)

    local dropdown
    dropdown = ns.Config.CreateDropdown(row.frame, DROPDOWN_WIDTH,
        function() return options end,
        get,
        function(value)
            set(value)
            ns.ChatBar:Refresh()
            ns.Config.RefreshDropdown(dropdown)
        end)
    dropdown:SetPoint("LEFT", row.label, "RIGHT", LABEL_GAP, 0)

    row.Refresh = function()
        ns.Config.RefreshDropdown(dropdown)
    end
end

local function AddSlider(labelText, minValue, maxValue, get, set)
    local row = CreateRow(labelText)

    local slider = CreateFrame("Frame", nil, row.frame, "MinimalSliderWithSteppersTemplate")
    slider:SetSize(SLIDER_WIDTH, ROW_HEIGHT)
    slider:SetPoint("LEFT", row.label, "RIGHT", LABEL_GAP, 0)

    local Label = MinimalSliderWithSteppersMixin.Label
    slider:Init(get(), minValue, maxValue, maxValue - minValue, {
        [Label.Right] = CreateMinimalSliderFormatter(Label.Right, function(value)
            return tostring(math.floor(value + 0.5))
        end),
    })

    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        value = math.floor(value + 0.5)
        -- Refresh drives SetValue, which lands here too; skip rebuilding the
        -- bar for a value that did not change.
        if value == get() then return end
        set(value)
        ns.ChatBar:Refresh()
    end, slider)

    row.Refresh = function()
        slider:SetValue(get())
    end
end

local function Create()
    local L = ns.L

    frame = CreateFrame("Frame", nil, UIParent)
    -- Hidden before OnHide is set: a new frame starts shown, and hiding it
    -- with the script in place would deselect the bar that is opening it.
    frame:Hide()
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetDontSavePosition(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    -- Wrapped rather than passed directly: OnDragStart hands over the mouse
    -- button, which StartMoving would read as its alwaysStartFromMouse flag.
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- However the dialog closes, the bar is deselected with it, the same as
    -- closing Blizzard's dialog deselects its frame.
    frame:SetScript("OnHide", function()
        ns.EditMode:Deselect()
    end)

    local border = CreateFrame("Frame", nil, frame, "DialogBorderTranslucentTemplate")
    border:SetAllPoints()

    -- The NoScripts variant: the stock close button hides its parent through
    -- HideUIPanel, which taints the panel manager when called from addon code.
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButtonNoScripts")
    closeButton:SetPoint("TOPRIGHT")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -TITLE_TOP)
    title:SetText(ns.EditMode.NAME)

    AddDropdown(L.ORIENTATION, {
        { value = "horizontal", text = L.ORIENTATION_HORIZONTAL },
        { value = "vertical", text = L.ORIENTATION_VERTICAL },
    },
    function() return Settings().orientation end,
    function(value) Settings().orientation = value end)

    AddDropdown(L.TEXT_POSITION, {
        { value = "inside", text = L.TEXT_POSITION_INSIDE },
        { value = "above", text = L.TEXT_POSITION_ABOVE },
    },
    function() return Settings().textPosition or "inside" end,
    function(value) Settings().textPosition = value end)

    AddSlider(L.BUTTON_SIZE, ns.ChatBar.BUTTON_SIZE_MIN, ns.ChatBar.BUTTON_SIZE_MAX,
        function() return Settings().buttonSize or ns.Defaults.buttonSize end,
        function(value) Settings().buttonSize = value end)

    AddSlider(L.FONT_SIZE, ns.ChatBar.FONT_SIZE_MIN, ns.ChatBar.FONT_SIZE_MAX,
        function() return Settings().fontSize or ns.Design:GetDefaultFontSize() end,
        function(value) Settings().fontSize = value end)

    -- Blizzard's label column is a fixed 100px, which several translated
    -- labels overrun. Size it to the widest label instead, never narrower.
    local labelWidth = LABEL_MIN_WIDTH
    for _, row in ipairs(rows) do
        labelWidth = math.max(labelWidth, math.ceil(row.label:GetStringWidth()))
    end
    local contentWidth = labelWidth + LABEL_GAP
        + math.max(DROPDOWN_WIDTH, SLIDER_WIDTH + SLIDER_VALUE_WIDTH)

    local top = TITLE_TOP + title:GetStringHeight() + SECTION_GAP
    local previous
    for _, row in ipairs(rows) do
        row.label:SetWidth(labelWidth)
        row.frame:SetWidth(contentWidth)
        if previous then
            row.frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -ROW_SPACING)
        else
            row.frame:SetPoint("TOPLEFT", PADDING, -top)
        end
        previous = row.frame
    end

    -- Blizzard's own label, so it reads the same as every other frame's reset
    -- button and comes translated. "Default" here is above the chat window.
    resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(contentWidth, BUTTON_HEIGHT)
    resetButton:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -SECTION_GAP)
    resetButton:SetText(HUD_EDIT_MODE_RESET_POSITION)
    resetButton:SetScript("OnClick", function()
        ns.ChatBar:ResetBarPosition()
        Dialog:Refresh()
    end)

    local rowsHeight = #rows * ROW_HEIGHT + (#rows - 1) * ROW_SPACING
    frame:SetSize(contentWidth + PADDING * 2,
        top + rowsHeight + SECTION_GAP + BUTTON_HEIGHT + PADDING)

    -- Where Blizzard opens its dialog for most frames. After that it stays
    -- wherever the player drags it, for the rest of the session.
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -250, 200)
end

function Dialog:Open()
    if not frame then
        Create()
    end
    self:Refresh()
    frame:Show()
end

function Dialog:Close()
    if frame then
        frame:Hide()
    end
end

-- Re-read every control from the profile. Called on open, and whenever the bar
-- moves, since the reset button depends on whether a position is saved.
function Dialog:Refresh()
    if not frame then return end

    for _, row in ipairs(rows) do
        row.Refresh()
    end
    resetButton:SetEnabled(Settings().barPosition ~= nil)
end
