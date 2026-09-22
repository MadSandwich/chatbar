-- ChatBar: Configuration and Settings UI
-- Config file

local addonName, ns = ...

-- Create Config object
local Config = {}
ns.Config = Config

-- Local reference to ChatBar
local ChatBar

-- Resetter called by the frame pool when a numbered-channel filter checkbox is released.
local function NumberedFilterCheckboxResetter(pool, cb)
    cb:Hide()
    cb:ClearAllPoints()
    cb:SetChecked(false)
    cb:SetScript("OnClick", nil)
    cb:SetScript("OnEnter", nil)
    cb:SetScript("OnLeave", nil)
    if cb.text then
        cb.text:SetText("")
        cb.text:SetTextColor(1, 1, 1)
    end
end

--[[
    Modern dropdown helper

    UIDropDownMenu has been deprecated since 11.0 (EasyMenu was removed outright
    in the same patch). DropdownButton + WowStyle1DropdownTemplate is the
    supported path and matches the rest of the modern settings UI.
]]

-- entriesFn() returns a list of { value, text, tooltipTitle, tooltipText }.
-- getFn() returns the currently selected value; setFn(value) applies a choice.
local function CreateDropdown(parent, width, entriesFn, getFn, setFn)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(width or 170)

    dropdown:SetupMenu(function(_, rootDescription)
        local selected = getFn()

        for _, entry in ipairs(entriesFn()) do
            local radio = rootDescription:CreateRadio(
                entry.text,
                function(value) return value == selected end,
                function(value)
                    setFn(value)
                    return MenuResponse.CloseAll
                end,
                entry.value)

            if entry.tooltipTitle or entry.tooltipText then
                radio:SetTooltip(function(tooltip)
                    if entry.tooltipTitle then
                        GameTooltip_SetTitle(tooltip, entry.tooltipTitle)
                    end
                    if entry.tooltipText and entry.tooltipText ~= "" then
                        GameTooltip_AddNormalLine(tooltip, entry.tooltipText)
                    end
                end)
            end
        end
    end)

    return dropdown
end

-- Re-read a dropdown's selection so its button text matches the settings.
local function RefreshDropdown(dropdown)
    if dropdown and dropdown.GenerateMenu then
        dropdown:GenerateMenu()
    end
end

--[[
    Live theme preview

    Renders a short sample bar through the real design engine, so what the
    player sees in settings is drawn by exactly the code that draws the bar.
]]

-- Real channel descriptors, not display strings: the preview runs them through
-- ChatBar's own glyph and colour lookups, so it shows the player's locale
-- letters and the same per-slot channel colours the live bar uses.
local PREVIEW_CHANNELS = {
    { channelType = "SAY",   isNumbered = false },
    { channelType = "PARTY", isNumbered = false },
    { channelType = "RAID",  isNumbered = false },
    { channelType = "GUILD", isNumbered = false },
    { isNumbered = true, id = 1 },
}

function Config:CreatePreview(parent)
    local preview = CreateFrame("Frame", nil, parent)
    preview:SetSize(260, 46)

    ns.Design:BuildBar(preview)

    preview.buttons = {}
    for i = 1, #PREVIEW_CHANNELS do
        local button = CreateFrame("Button", nil, preview)
        button:EnableMouse(false)
        ns.Design:BuildButton(button)
        preview.buttons[i] = button
    end

    return preview
end

function Config:UpdatePreview(preview)
    if not preview then return end

    local settings = ChatBar:GetSettings()
    local size = settings.buttonSize or 24
    local padding = ns.Design:GetPadding()
    local spacing = ns.Design:GetSpacing()

    -- Masks and animations from the previous theme have to go before restyling,
    -- exactly as the live bar does on a theme swap.
    for _, button in ipairs(preview.buttons) do
        ns.Design:ReleaseButton(button)
    end

    ns.Design:StyleBar(preview)

    for i, button in ipairs(preview.buttons) do
        local channelData = PREVIEW_CHANNELS[i]
        button.text:SetText(ChatBar:GetButtonGlyph(channelData))

        ns.Design:StyleButton(button, {
            size = size,
            channelColor = ChatBar:GetChannelColor(channelData),
            fontSize = settings.fontSize or ns.Design:GetDefaultFontSize(),
            -- Honour the real setting: a preview that always says "inside"
            -- misrepresents the bar for anyone using labels above.
            textPosition = settings.textPosition,
            orientation = "horizontal",
            enabled = true,
            -- Second sample shows what the active channel looks like.
            active = (i == 2),
        })

        button:ClearAllPoints()
        ns.Pixel.Point(button, "TOPLEFT", preview, "TOPLEFT",
            padding + ((i - 1) * (size + spacing)), -padding)
    end

    local width = (size * #preview.buttons) + (spacing * (#preview.buttons - 1)) + (padding * 2)
    local height = size + (padding * 2)
    ns.Pixel.Size(preview, width, height)
end

-- Custom accent picker. Uses the modern SetupColorPickerAndShow entry point
-- rather than poking ColorPickerFrame's fields directly.
function Config:OpenAccentColorPicker()
    local settings = ChatBar:GetSettings()
    local r, g, b = ns.Theme:GetAccent()

    local function Apply(nr, ng, nb)
        settings.accent = "custom"
        settings.accentColor = { r = nr, g = ng, b = nb }
        ns.Theme:NotifyChanged("accent")
        if Config.panel then
            Config:RefreshPanel(Config.panel)
        end
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b,
        hasOpacity = false,
        swatchFunc = function()
            Apply(ColorPickerFrame:GetColorRGB())
        end,
        cancelFunc = function(previous)
            if previous then
                Apply(previous.r, previous.g, previous.b)
            end
        end,
    })
end

-- Background surface colour picker.
--
-- Seeded from whatever is on screen right now: with no override stored, that is
-- the theme's own bar colour, so the picker opens on the current look instead of
-- an arbitrary swatch.
function Config:OpenBackgroundColorPicker()
    local settings = ChatBar:GetSettings()
    local current = settings.backgroundColor
    local r, g, b

    if current then
        r, g, b = current.r, current.g, current.b
    else
        local theme = ns.Design:GetTheme()
        local barCfg = theme.bar or {}
        r, g, b = ns.Theme:Resolve(barCfg.gradient and barCfg.gradient.from or barCfg.fill)
    end

    local function Apply(nr, ng, nb)
        settings.backgroundColor = { r = nr, g = ng, b = nb }
        ns.Theme:NotifyChanged("background")
        if Config.panel then
            Config:RefreshPanel(Config.panel)
        end
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b,
        hasOpacity = false,
        swatchFunc = function()
            Apply(ColorPickerFrame:GetColorRGB())
        end,
        cancelFunc = function(previous)
            if previous then
                Apply(previous.r, previous.g, previous.b)
            end
        end,
    })
end

-- Initialize config (called from ChatBar after ADDON_LOADED)
function Config:Initialize()
    ChatBar = ns.ChatBar
    self:CreateSettingsPanel()
    self:RegisterSlashCommands()
end

-- Create settings panel with scroll
function Config:CreateSettingsPanel()
    local L = ns.L
    
    local panel = CreateFrame("Frame", "ChatBarConfigPanel", UIParent)
    panel.name = L.ADDON_NAME
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "ChatBarConfigScroll", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)
    
    -- Create scroll child (content frame)
    local content = CreateFrame("Frame", "ChatBarConfigContent", scrollFrame)
    content:SetSize(600, 800) -- Will expand as needed
    scrollFrame:SetScrollChild(content)
    
    -- Title
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.SETTINGS_TITLE)
    
    -- Version
    local version = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText(L.VERSION .. " " .. ChatBar.VERSION)
    version:SetTextColor(0.5, 0.5, 0.5)
    
    local yOffset = -80
    
    -- Profile Mode Section
    local profileLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 16, yOffset)
    profileLabel:SetText(L.PROFILE_MODE)
    
    local profileAccount = CreateFrame("CheckButton", "ChatBarProfileAccount", content, "UIRadioButtonTemplate")
    profileAccount:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", 0, -8)
    profileAccount.text:SetFontObject("GameFontHighlight")
    profileAccount.text:SetPoint("LEFT", profileAccount, "RIGHT", 0, 0)
    profileAccount.text:SetText(L.PROFILE_ACCOUNT)
    
    local profileCharacter = CreateFrame("CheckButton", "ChatBarProfileCharacter", content, "UIRadioButtonTemplate")
    profileCharacter:SetPoint("TOPLEFT", profileAccount, "BOTTOMLEFT", 0, -4)
    profileCharacter.text:SetFontObject("GameFontHighlight")
    profileCharacter.text:SetPoint("LEFT", profileCharacter, "RIGHT", 0, 0)
    profileCharacter.text:SetText(L.PROFILE_CHARACTER)
    
    profileAccount:SetScript("OnClick", function(self)
        ns.db.profileMode = "account"
        profileCharacter:SetChecked(false)
        ChatBar:Refresh()
    end)
    
    profileCharacter:SetScript("OnClick", function(self)
        ns.db.profileMode = "character"
        profileAccount:SetChecked(false)
        ChatBar:Refresh()
    end)
    
    content.profileAccount = profileAccount
    content.profileCharacter = profileCharacter
    
    yOffset = yOffset - 80
    
    -- Appearance Section: theme, button shape, accent colour
    local appearanceLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    appearanceLabel:SetPoint("TOPLEFT", 16, yOffset)
    appearanceLabel:SetText(L.APPEARANCE)

    local COL_W, COL_GAP = 170, 12
    local COL_X = { 16, 16 + COL_W + COL_GAP, 16 + (COL_W + COL_GAP) * 2 }

    -- Two rows of three columns. ROW_Y is the label baseline for each row; the
    -- control sits 16px below its label.
    local ROW_Y = { yOffset - 24, yOffset - 74 }

    local function ColumnLabel(text, column, row)
        local fs = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", COL_X[column], ROW_Y[row or 1])
        fs:SetText(text)
        fs:SetTextColor(0.75, 0.75, 0.75)
        return fs
    end

    local function ControlPoint(control, column, row, dx)
        control:SetPoint("TOPLEFT", COL_X[column] + (dx or -2), ROW_Y[row or 1] - 16)
    end

    -- Theme -----------------------------------------------------------------
    ColumnLabel(L.THEME, 1, 1)

    local themeDropdown = CreateDropdown(content, COL_W,
        function()
            local entries = {}
            for _, theme in ipairs(ns.Design:GetAvailableThemes()) do
                entries[#entries + 1] = {
                    value = theme.id,
                    text = theme.name,
                    tooltipTitle = theme.name,
                    tooltipText = theme.description,
                }
            end
            return entries
        end,
        function()
            return ChatBar:GetSettings().theme or "Flat"
        end,
        function(value)
            local settings = ChatBar:GetSettings()
            if settings.theme == value then return end
            settings.theme = value
            -- A theme carries its own text scale; adopt it rather than leaving
            -- the player on a size tuned for the theme they just left.
            ChatBar:ApplyThemeFontDefault(settings)
            -- Shape follows the new theme unless the player pinned one.
            ns.Theme:NotifyChanged("theme")
            Config:RefreshPanel(Config.panel)
        end)
    themeDropdown:SetDefaultText(L.THEME)
    ControlPoint(themeDropdown, 1, 1)
    content.themeDropdown = themeDropdown

    -- Button shape ----------------------------------------------------------
    content.shapeLabel = ColumnLabel(L.BUTTON_SHAPE, 2, 1)

    local shapeDropdown = CreateDropdown(content, COL_W,
        function()
            local entries = {}
            -- Only the shapes this client can actually cut: a shape whose mask
            -- art is missing silently degrades to square, and offering a choice
            -- that does nothing is worse than not offering it.
            for _, id in ipairs(ns.Design:GetAvailableShapes()) do
                local key = "SHAPE_" .. id:upper()
                entries[#entries + 1] = { value = id, text = L[key] or id }
            end
            return entries
        end,
        function()
            return ChatBar:GetSettings().buttonShape or "square"
        end,
        function(value)
            local settings = ChatBar:GetSettings()
            settings.buttonShape = value
            ns.Theme:NotifyChanged("shape")
            Config:RefreshPanel(Config.panel)
        end)
    shapeDropdown:SetDefaultText(L.SHAPE_SQUARE)
    ControlPoint(shapeDropdown, 2, 1)
    content.shapeDropdown = shapeDropdown

    -- Accent colour ---------------------------------------------------------
    ColumnLabel(L.ACCENT, 3, 1)

    local accentDropdown = CreateDropdown(content, COL_W,
        function()
            local entries = {}
            for _, id in ipairs(ns.Theme:GetAccentChoices()) do
                local key = "ACCENT_" .. id:upper()
                entries[#entries + 1] = { value = id, text = L[key] or id }
            end
            return entries
        end,
        function()
            return ChatBar:GetSettings().accent or "class"
        end,
        function(value)
            local settings = ChatBar:GetSettings()
            settings.accent = value
            if value == "custom" then
                Config:OpenAccentColorPicker()
            else
                ns.Theme:NotifyChanged("accent")
                Config:RefreshPanel(Config.panel)
            end
        end)
    accentDropdown:SetDefaultText(L.ACCENT)
    ControlPoint(accentDropdown, 3, 1)
    content.accentDropdown = accentDropdown

    -- Font ------------------------------------------------------------------
    ColumnLabel(L.FONT, 1, 2)

    local fontDropdown = CreateDropdown(content, COL_W,
        function()
            local entries = {}
            for _, choice in ipairs(ns.Theme:GetFontChoices()) do
                entries[#entries + 1] = {
                    value = choice.id,
                    text = L[choice.nameKey] or choice.id,
                }
            end
            return entries
        end,
        function()
            return ns.Theme:GetFontId()
        end,
        function(value)
            local settings = ChatBar:GetSettings()
            if settings.font == value then return end
            settings.font = value
            ns.Theme:NotifyChanged("font")
            Config:RefreshPanel(Config.panel)
        end)
    fontDropdown:SetDefaultText(L.FONT)
    ControlPoint(fontDropdown, 1, 2)
    content.fontDropdown = fontDropdown

    -- Background colour -----------------------------------------------------
    ColumnLabel(L.BACKGROUND_COLOR, 2, 2)

    local swatch = CreateFrame("Button", nil, content)
    swatch:SetSize(COL_W, 22)
    ControlPoint(swatch, 2, 2, 0)

    local swatchFill = swatch:CreateTexture(nil, "ARTWORK")
    swatchFill:SetAllPoints()
    ns.Pixel.NoSnap(swatchFill)
    swatch.fill = swatchFill
    ns.Pixel.CreateBorder(swatch, 1, 1, 1, 0.25)

    swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    swatch:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            -- Right-click hands the colour back to the theme rather than
            -- forcing the player to guess the theme's own value.
            local settings = ChatBar:GetSettings()
            settings.backgroundColor = nil
            ns.Theme:NotifyChanged("background")
            Config:RefreshPanel(Config.panel)
        else
            Config:OpenBackgroundColorPicker()
        end
    end)
    swatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.BACKGROUND_COLOR)
        GameTooltip:AddLine(L.BACKGROUND_COLOR_HINT, 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
    content.backgroundSwatch = swatch

    -- Opacity ---------------------------------------------------------------
    ColumnLabel(L.BACKGROUND_OPACITY, 3, 2)

    local opacitySlider = CreateFrame("Slider", "ChatBarOpacitySlider", content, "OptionsSliderTemplate")
    opacitySlider:SetMinMaxValues(5, 100)
    opacitySlider:SetValueStep(5)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetWidth(COL_W - 12)
    ControlPoint(opacitySlider, 3, 2, 4)

    _G[opacitySlider:GetName() .. "Low"]:SetText("5%")
    _G[opacitySlider:GetName() .. "High"]:SetText("100%")

    opacitySlider:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.BACKGROUND_OPACITY)
        GameTooltip:AddLine(L.BACKGROUND_OPACITY_HINT, 0.7, 0.7, 0.7, true)
        if not self:IsEnabled() then
            GameTooltip:AddLine(L.BACKGROUND_OPACITY_NO_BAR, 1, 0.5, 0.5, true)
        end
        GameTooltip:Show()
    end)
    opacitySlider:SetScript("OnLeave", function() GameTooltip:Hide() end)

    opacitySlider:SetScript("OnValueChanged", function(self, value)
        local settings = ChatBar:GetSettings()
        local opacity = value / 100

        _G[self:GetName() .. "Text"]:SetText(string.format("%d%%", math.floor(value)))

        -- RefreshPanel drives SetValue to sync the widget, which fires this
        -- handler again; bail on a no-op rather than triggering a second full
        -- rebuild of the bar for a value that did not change.
        if math.abs((settings.backgroundOpacity or 1) - opacity) < 0.001 then return end

        settings.backgroundOpacity = opacity
        ChatBar:Refresh()
        Config:UpdatePreview(content.preview)
    end)
    content.opacitySlider = opacitySlider

    -- Theme description -----------------------------------------------------
    local themeDescription = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    themeDescription:SetPoint("TOPLEFT", 16, yOffset - 124)
    themeDescription:SetTextColor(0.6, 0.6, 0.6)
    themeDescription:SetWidth(540)
    themeDescription:SetJustifyH("LEFT")
    content.themeDescription = themeDescription

    -- Live preview ----------------------------------------------------------
    local preview = self:CreatePreview(content)
    preview:SetPoint("TOPLEFT", 16, yOffset - 146)
    content.preview = preview

    yOffset = yOffset - 220
    
    -- Orientation Section
    local orientationLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientationLabel:SetPoint("TOPLEFT", 16, yOffset)
    orientationLabel:SetText(L.ORIENTATION)
    
    local orientationHorizontal = CreateFrame("CheckButton", "ChatBarOrientationHorizontal", content, "UIRadioButtonTemplate")
    orientationHorizontal:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, -8)
    orientationHorizontal.text:SetFontObject("GameFontHighlight")
    orientationHorizontal.text:SetPoint("LEFT", orientationHorizontal, "RIGHT", 0, 0)
    orientationHorizontal.text:SetText(L.ORIENTATION_HORIZONTAL)
    
    local orientationVertical = CreateFrame("CheckButton", "ChatBarOrientationVertical", content, "UIRadioButtonTemplate")
    orientationVertical:SetPoint("LEFT", orientationHorizontal, "RIGHT", 120, 0)
    orientationVertical.text:SetFontObject("GameFontHighlight")
    orientationVertical.text:SetPoint("LEFT", orientationVertical, "RIGHT", 0, 0)
    orientationVertical.text:SetText(L.ORIENTATION_VERTICAL)
    
    orientationHorizontal:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.orientation = "horizontal"
        orientationVertical:SetChecked(false)
        ChatBar:Refresh()
    end)
    
    orientationVertical:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.orientation = "vertical"
        orientationHorizontal:SetChecked(false)
        ChatBar:Refresh()
    end)
    
    content.orientationHorizontal = orientationHorizontal
    content.orientationVertical = orientationVertical
    
    yOffset = yOffset - 60
    
    -- Two-column layout for sizes
    -- Font Size Section (Left column)
    local fontSizeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontSizeLabel:SetPoint("TOPLEFT", 16, yOffset)
    fontSizeLabel:SetText("Font Size:")
    
    local fontSizeSlider = CreateFrame("Slider", "ChatBarFontSizeSlider", content, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", fontSizeLabel, "BOTTOMLEFT", 4, -20)
    fontSizeSlider:SetMinMaxValues(8, 24)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(120)
    
    -- Set slider labels
    _G[fontSizeSlider:GetName() .. "Low"]:SetText("8")
    _G[fontSizeSlider:GetName() .. "High"]:SetText("24")
    _G[fontSizeSlider:GetName() .. "Text"]:SetText("12")
    
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        local settings = ChatBar:GetSettings()
        settings.fontSize = value
        _G[self:GetName() .. "Text"]:SetText(tostring(math.floor(value)))
        ChatBar:Refresh()
        Config:UpdatePreview(content.preview)
    end)
    
    content.fontSizeSlider = fontSizeSlider
    
    -- Button Size Section (Right column)
    local buttonSizeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    buttonSizeLabel:SetPoint("TOPLEFT", 300, yOffset)
    buttonSizeLabel:SetText("Button Size:")
    
    local buttonSizeSlider = CreateFrame("Slider", "ChatBarButtonSizeSlider", content, "OptionsSliderTemplate")
    buttonSizeSlider:SetPoint("TOPLEFT", buttonSizeLabel, "BOTTOMLEFT", 4, -20)
    buttonSizeSlider:SetMinMaxValues(10, 32)
    buttonSizeSlider:SetValueStep(1)
    buttonSizeSlider:SetObeyStepOnDrag(true)
    buttonSizeSlider:SetWidth(120)
    
    -- Set slider labels
    _G[buttonSizeSlider:GetName() .. "Low"]:SetText("10")
    _G[buttonSizeSlider:GetName() .. "High"]:SetText("32")
    _G[buttonSizeSlider:GetName() .. "Text"]:SetText("18")
    
    buttonSizeSlider:SetScript("OnValueChanged", function(self, value)
        local settings = ChatBar:GetSettings()
        settings.buttonSize = value
        _G[self:GetName() .. "Text"]:SetText(tostring(math.floor(value)))
        ChatBar:Refresh()
        Config:UpdatePreview(content.preview)
    end)
    
    content.buttonSizeSlider = buttonSizeSlider
    
    yOffset = yOffset - 80
    
    -- Text Position Section
    local textPosLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textPosLabel:SetPoint("TOPLEFT", 16, yOffset)
    textPosLabel:SetText(L.TEXT_POSITION)
    
    local textPosInside = CreateFrame("CheckButton", "ChatBarTextPosInside", content, "UIRadioButtonTemplate")
    textPosInside:SetPoint("TOPLEFT", textPosLabel, "BOTTOMLEFT", 0, -8)
    textPosInside.text:SetFontObject("GameFontHighlight")
    textPosInside.text:SetPoint("LEFT", textPosInside, "RIGHT", 0, 0)
    textPosInside.text:SetText(L.TEXT_POSITION_INSIDE)
    
    local textPosAbove = CreateFrame("CheckButton", "ChatBarTextPosAbove", content, "UIRadioButtonTemplate")
    textPosAbove:SetPoint("LEFT", textPosInside, "RIGHT", 120, 0)
    textPosAbove.text:SetFontObject("GameFontHighlight")
    textPosAbove.text:SetPoint("LEFT", textPosAbove, "RIGHT", 0, 0)
    textPosAbove.text:SetText(L.TEXT_POSITION_ABOVE)
    
    textPosInside:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.textPosition = "inside"
        textPosAbove:SetChecked(false)
        ChatBar:Refresh()
    end)
    
    textPosAbove:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.textPosition = "above"
        textPosInside:SetChecked(false)
        ChatBar:Refresh()
    end)
    
    content.textPosInside = textPosInside
    content.textPosAbove = textPosAbove
    
    yOffset = yOffset - 50
    
    -- Flash Notifications Section
    local flashCheckbox = CreateFrame("CheckButton", "ChatBarFlashNotifications", content, "UICheckButtonTemplate")
    flashCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    flashCheckbox.text:SetFontObject("GameFontHighlight")
    flashCheckbox.text:SetPoint("LEFT", flashCheckbox, "RIGHT", 0, 0)
    flashCheckbox.text:SetText(L.FLASH_NOTIFICATIONS_DESC)
    
    flashCheckbox:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.flashNotifications = self:GetChecked()
    end)
    
    content.flashCheckbox = flashCheckbox
    
    yOffset = yOffset - 30
    
    -- Channel History Cycling Section
    local historyCheckbox = CreateFrame("CheckButton", "ChatBarChannelHistory", content, "UICheckButtonTemplate")
    historyCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    historyCheckbox.text:SetFontObject("GameFontHighlight")
    historyCheckbox.text:SetPoint("LEFT", historyCheckbox, "RIGHT", 0, 0)
    -- Constrain width so long (localized) labels wrap instead of running off-screen.
    historyCheckbox.text:SetWidth(500)
    historyCheckbox.text:SetJustifyH("LEFT")
    historyCheckbox.text:SetText(L.CHANNEL_HISTORY_DESC)
    
    historyCheckbox:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        if not settings.channelHistory then
            settings.channelHistory = {}
        end
        settings.channelHistory.enabled = self:GetChecked()
    end)
    
    content.historyCheckbox = historyCheckbox
    
    -- Extra spacing: the wrapped label can occupy two lines for longer locales.
    yOffset = yOffset - 44
    
    -- Hide Loaded Message Section
    local hideLoadedCheckbox = CreateFrame("CheckButton", "ChatBarHideLoadedMessage", content, "UICheckButtonTemplate")
    hideLoadedCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    hideLoadedCheckbox.text:SetFontObject("GameFontHighlight")
    hideLoadedCheckbox.text:SetPoint("LEFT", hideLoadedCheckbox, "RIGHT", 0, 0)
    hideLoadedCheckbox.text:SetText(L.HIDE_LOADED_MESSAGE)
    
    hideLoadedCheckbox:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.hideLoadedMessage = self:GetChecked()
    end)
    
    content.hideLoadedCheckbox = hideLoadedCheckbox
    
    yOffset = yOffset - 40
    
    -- Channel Configuration Section
    local channelLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", 16, yOffset)
    channelLabel:SetText(L.ENABLED_CHANNELS)
    
    local channelCheckboxes = {}
    local checkYOffset = yOffset - 24
    local column = 0
    local row = 0
    
    -- Create checkboxes for each channel
    local channelOrder = {}
    for channelType, config in pairs(ns.ChannelInfo) do
        table.insert(channelOrder, channelType)
    end
    table.sort(channelOrder)
    
    for _, channelType in ipairs(channelOrder) do
        local info = ns.ChannelInfo[channelType]
        local checkbox = CreateFrame("CheckButton", "ChatBarChannel" .. channelType, content, "UICheckButtonTemplate")
        
        local xPos = 20 + (column * 200)
        local yPos = checkYOffset - (row * 28)
        
        checkbox:SetPoint("TOPLEFT", xPos, yPos)
        checkbox.text:SetFontObject("GameFontHighlight")
        checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
        checkbox.text:SetText(L[info.labelKey] or info.labelKey)
        
        checkbox.channelType = channelType
        checkbox:SetScript("OnClick", function(self)
            local settings = ChatBar:GetSettings()
            settings.channels[channelType].enabled = self:GetChecked()
            ChatBar:UpdateButtons()
        end)
        
        channelCheckboxes[channelType] = checkbox
        
        column = column + 1
        if column >= 2 then
            column = 0
            row = row + 1
        end
    end
    
    content.channelCheckboxes = channelCheckboxes
    
    -- Numbered Channels Section
    yOffset = checkYOffset - (row + 1) * 28 - 20
    
    local numberedLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    numberedLabel:SetPoint("TOPLEFT", 16, yOffset)
    numberedLabel:SetText(L.NUMBERED_CHANNELS)
    
    local numberedEnabled = CreateFrame("CheckButton", "ChatBarNumberedEnabled", content, "UICheckButtonTemplate")
    numberedEnabled:SetPoint("TOPLEFT", numberedLabel, "BOTTOMLEFT", 0, -8)
    numberedEnabled.text:SetFontObject("GameFontHighlight")
    numberedEnabled.text:SetPoint("LEFT", numberedEnabled, "RIGHT", 0, 0)
    numberedEnabled.text:SetText(L.SHOW_NUMBERED_CHANNELS)
    
    numberedEnabled:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.numberedChannels.enabled = self:GetChecked()
        ChatBar:UpdateButtons()
        Config:BuildNumberedChannelCheckboxes(content)
    end)
    
    content.numberedEnabled = numberedEnabled
    
    -- Sub-label for the per-channel filter list
    local numberedFilterLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    numberedFilterLabel:SetPoint("TOPLEFT", numberedEnabled, "BOTTOMLEFT", 20, -10)
    numberedFilterLabel:SetText(L.NUMBERED_CHANNEL_FILTERS)
    content.numberedFilterLabel = numberedFilterLabel
    
    -- Container for the dynamic per-channel filter checkboxes
    local numberedFilterSection = CreateFrame("Frame", nil, content)
    numberedFilterSection:SetPoint("TOPLEFT", numberedFilterLabel, "BOTTOMLEFT", 0, -4)
    numberedFilterSection:SetSize(560, 0)
    content.numberedFilterSection = numberedFilterSection
    
    -- Frame pool for the dynamic filter checkboxes (avoids frame accumulation on rebuild)
    content.numberedFilterPool = CreateFramePool("CheckButton", numberedFilterSection, "UICheckButtonTemplate", NumberedFilterCheckboxResetter)
    
    -- Placeholder shown when no numbered channels are currently joined
    local numberedNoneLabel = numberedFilterSection:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    numberedNoneLabel:SetPoint("TOPLEFT", 4, -4)
    numberedNoneLabel:SetText(L.NUMBERED_CHANNEL_NONE)
    numberedNoneLabel:Hide()
    content.numberedNoneLabel = numberedNoneLabel
    
    -- Lock Position Section — anchored relative to the dynamic filter section so it
    -- repositions automatically when the filter list grows or shrinks.
    local lockLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lockLabel:SetPoint("TOPLEFT", numberedFilterSection, "BOTTOMLEFT", -4, -20)
    lockLabel:SetText("Position:")
    
    local lockPosition = CreateFrame("CheckButton", "ChatBarLockPosition", content, "UICheckButtonTemplate")
    lockPosition:SetPoint("TOPLEFT", lockLabel, "BOTTOMLEFT", 0, -8)
    lockPosition.text:SetFontObject("GameFontHighlight")
    lockPosition.text:SetPoint("LEFT", lockPosition, "RIGHT", 0, 0)
    lockPosition.text:SetText("Lock bar position")
    
    lockPosition:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.lockPosition = self:GetChecked()
    end)
    
    content.lockPosition = lockPosition
    
    -- Store content reference
    panel.content = content
    
    -- Refresh panel callback
    panel.refresh = function()
        Config:RefreshPanel(panel)
    end
    
    -- Auto-refresh on show
    panel:SetScript("OnShow", function(self)
        if self.refresh then
            self.refresh()
        end
    end)
    
    self.panel = panel
    
    -- Live-refresh the per-channel filter list whenever joined channels change.
    local channelUpdateListener = CreateFrame("Frame")
    channelUpdateListener:RegisterEvent("CHANNEL_UI_UPDATE")
    channelUpdateListener:SetScript("OnEvent", function()
        if panel:IsVisible() then
            Config:BuildNumberedChannelCheckboxes(panel.content)
        end
    end)
    
    -- Add to interface options using the Settings API (WoW 10.0+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        panel.category = category
        self.settingsCategory = category
    end
    
    return panel
end

-- Refresh panel with current settings
function Config:RefreshPanel(panel)
    local content = panel.content
    local settings = ChatBar:GetSettings()
    
    -- Profile mode
    content.profileAccount:SetChecked(ns.db.profileMode == "account")
    content.profileCharacter:SetChecked(ns.db.profileMode == "character")
    
    -- Appearance dropdowns: re-read so the button text follows the settings,
    -- including changes made from a slash command or a profile switch.
    RefreshDropdown(content.themeDropdown)
    RefreshDropdown(content.shapeDropdown)
    RefreshDropdown(content.accentDropdown)
    RefreshDropdown(content.fontDropdown)

    -- Background swatch shows the override when one is set, otherwise the
    -- theme's own colour, so it always reflects what is actually on screen.
    if content.backgroundSwatch then
        local color = settings.backgroundColor
        local r, g, b
        if color then
            r, g, b = color.r, color.g, color.b
        else
            local theme = ns.Design:GetTheme()
            local barCfg = theme.bar or {}
            r, g, b = ns.Theme:Resolve(barCfg.gradient and barCfg.gradient.from or barCfg.fill)
        end
        content.backgroundSwatch.fill:SetColorTexture(r, g, b, 1)
    end

    -- Themes whose shape is part of their identity fix it. Grey the control out
    -- rather than hiding it, so the row keeps its layout and the reason the
    -- choice is unavailable stays visible next to the theme that caused it.
    if content.shapeDropdown then
        local allowed = ns.Design:AllowsShapeChoice()
        content.shapeDropdown:SetEnabled(allowed)
        content.shapeDropdown:SetAlpha(allowed and 1 or 0.4)
        if content.shapeLabel then
            content.shapeLabel:SetAlpha(allowed and 1 or 0.4)
        end
    end

    if content.opacitySlider then
        local percent = math.floor((settings.backgroundOpacity or 1) * 100 + 0.5)
        content.opacitySlider:SetValue(percent)
        _G[content.opacitySlider:GetName() .. "Text"]:SetText(string.format("%d%%", percent))

        -- Themes that draw no bar backdrop have nothing for this slider to act
        -- on; grey it out rather than letting it look live and do nothing.
        local barCfg = ns.Design:GetTheme().bar or {}
        local hasBar = barCfg.show ~= false
        content.opacitySlider:SetEnabled(hasBar)
        content.opacitySlider:SetAlpha(hasBar and 1 or 0.4)
    end

    if content.themeDescription then
        local theme = ns.Theme:Get(settings.theme or "Flat")
        if theme then
            local L = ns.L
            local description = (theme.descKey and L[theme.descKey]) or ""
            content.themeDescription:SetText(string.format("%s |cff888888%s %s|r",
                description, L.SKIN_AUTHOR, theme.author or "ChatBar"))
        else
            content.themeDescription:SetText("")
        end
    end

    self:UpdatePreview(content.preview)
    
    -- Orientation
    content.orientationHorizontal:SetChecked(settings.orientation == "horizontal")
    content.orientationVertical:SetChecked(settings.orientation == "vertical")
    
    -- Channel checkboxes
    for channelType, checkbox in pairs(content.channelCheckboxes) do
        if settings.channels[channelType] then
            checkbox:SetChecked(settings.channels[channelType].enabled)
        end
    end
    
    -- Numbered channels
    content.numberedEnabled:SetChecked(settings.numberedChannels.enabled)
    
    -- Rebuild per-channel filter checkboxes to match current profile and channel list.
    self:BuildNumberedChannelCheckboxes(content)
    
    -- Lock position
    content.lockPosition:SetChecked(settings.lockPosition)
    
    -- Font size
    if content.fontSizeSlider then
        content.fontSizeSlider:SetValue(settings.fontSize or 12)
        _G[content.fontSizeSlider:GetName() .. "Text"]:SetText(tostring(math.floor(settings.fontSize or 12)))
    end
    
    -- Button size
    if content.buttonSizeSlider then
        content.buttonSizeSlider:SetValue(settings.buttonSize or 24)
    end
    
    -- Text position
    if content.textPosInside and content.textPosAbove then
        local textPos = settings.textPosition or "inside"
        content.textPosInside:SetChecked(textPos == "inside")
        content.textPosAbove:SetChecked(textPos == "above")
    end
    
    -- Flash notifications
    if content.flashCheckbox then
        content.flashCheckbox:SetChecked(settings.flashNotifications ~= false)
    end
    
    -- Channel history cycling
    if content.historyCheckbox then
        local ch = settings.channelHistory
        content.historyCheckbox:SetChecked(not ch or ch.enabled ~= false)
    end
    
    -- Hide loaded message
    if content.hideLoadedCheckbox then
        content.hideLoadedCheckbox:SetChecked(settings.hideLoadedMessage ~= false)
    end
end

-- Build (or rebuild) per-channel filter checkboxes under the numbered-channels master toggle.
-- Safe to call multiple times; uses a frame pool to avoid accumulation.
function Config:BuildNumberedChannelCheckboxes(content)
    local L       = ns.L
    local settings = ChatBar:GetSettings()
    local section = content.numberedFilterSection
    local pool    = content.numberedFilterPool

    pool:ReleaseAll()

    local masterEnabled = settings.numberedChannels.enabled

    -- Collapse the filter section while the master toggle is off.
    if not masterEnabled then
        if content.numberedFilterLabel then content.numberedFilterLabel:Hide() end
        section:Hide()
        section:SetHeight(0)
        return
    end

    if content.numberedFilterLabel then content.numberedFilterLabel:Show() end
    section:Show()

    local channelList = { GetChannelList() }
    local channels = {}
    for i = 1, #channelList, 3 do
        local id       = channelList[i]
        local name     = channelList[i + 1]
        local disabled = channelList[i + 2]
        if id and name then
            table.insert(channels, { id = id, name = name, disabled = disabled })
        end
    end

    content.numberedNoneLabel:SetShown(#channels == 0)

    if #channels == 0 then
        section:SetHeight(28)
        return
    end

    local excluded = settings.numberedChannels.excluded or {}
    local column = 0
    local row    = 0

    for _, ch in ipairs(channels) do
        local cb = pool:Acquire()
        cb:SetPoint("TOPLEFT", column * 260, -(row * 28))
        cb:Show()
        cb:SetChecked(not excluded[ch.name])

        -- UICheckButtonTemplate already supplies the label FontString (aliased to
        -- .text on load); restyle it to match the other checkbox labels here.
        cb.text:SetFontObject("GameFontHighlight")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 0, 0)
        cb.text:SetText(ch.name)

        if ch.disabled then
            cb.text:SetTextColor(0.5, 0.5, 0.5)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(L.NUMBERED_CHANNEL_INACTIVE)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            cb.text:SetTextColor(1, 1, 1)
        end

        local channelName = ch.name
        cb:SetScript("OnClick", function(self)
            local s = ChatBar:GetSettings()
            if not s.numberedChannels.excluded then
                s.numberedChannels.excluded = {}
            end
            if self:GetChecked() then
                s.numberedChannels.excluded[channelName] = nil
            else
                s.numberedChannels.excluded[channelName] = true
            end
            ChatBar:UpdateButtons()
        end)

        column = column + 1
        if column >= 2 then
            column = 0
            row    = row + 1
        end
    end

    local totalRows = row + (column > 0 and 1 or 0)
    section:SetHeight(math.max(28, totalRows * 28))
end

-- Open settings panel
function Config:OpenSettings()
    if not self.settingsCategory then
        local L = ns.L
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_SETTINGS_LOADING))
        return
    end
    
    if Settings and Settings.OpenToCategory and self.settingsCategory.GetID then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    end
end

-- Register slash commands
function Config:RegisterSlashCommands()
    SLASH_CHATBAR1 = "/chatbar"
    SLASH_CHATBAR2 = "/cb"
    SlashCmdList["CHATBAR"] = function(msg)
        ChatBar:HandleSlashCommand(msg)
    end
end
