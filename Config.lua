-- ChatBar: Configuration and Settings UI
-- Config file

local addonName, ns = ...

-- Create Config object
local Config = {}
ns.Config = Config

-- Local reference to ChatBar
local ChatBar

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
    panel.name = L.ADDON_NAME or "ChatBar"
    
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
    title:SetText(L.SETTINGS_TITLE or "ChatBar Settings")
    
    -- Version
    local version = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText((L.VERSION or "Version") .. " " .. ChatBar.VERSION)
    version:SetTextColor(0.5, 0.5, 0.5)
    
    local yOffset = -80
    
    -- Profile Mode Section
    local profileLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 16, yOffset)
    profileLabel:SetText(L.PROFILE_MODE or "Profile Mode:")
    
    local profileAccount = CreateFrame("CheckButton", "ChatBarProfileAccount", content, "UIRadioButtonTemplate")
    profileAccount:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", 0, -8)
    profileAccount.text = profileAccount:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    profileAccount.text:SetPoint("LEFT", profileAccount, "RIGHT", 0, 0)
    profileAccount.text:SetText(L.PROFILE_ACCOUNT or "Account-wide (shared across all characters)")
    
    local profileCharacter = CreateFrame("CheckButton", "ChatBarProfileCharacter", content, "UIRadioButtonTemplate")
    profileCharacter:SetPoint("TOPLEFT", profileAccount, "BOTTOMLEFT", 0, -4)
    profileCharacter.text = profileCharacter:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    profileCharacter.text:SetPoint("LEFT", profileCharacter, "RIGHT", 0, 0)
    profileCharacter.text:SetText(L.PROFILE_CHARACTER or "Per-character settings")
    
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
    
    -- Button Theme Section (Radio Buttons)
    local buttonThemeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    buttonThemeLabel:SetPoint("TOPLEFT", 16, yOffset)
    buttonThemeLabel:SetText(L.BUTTON_THEME or "Button Theme:")
    
    local buttonThemeRadios = {}
    local themeYOffset = yOffset - 24
    local themeOrder = {"classic", "modern", "minimal"}
    
    for i, themeName in ipairs(themeOrder) do
        local radio = CreateFrame("CheckButton", "ChatBarButtonTheme" .. themeName, content, "UIRadioButtonTemplate")
        radio:SetPoint("TOPLEFT", 16, themeYOffset - ((i - 1) * 28))
        radio.text = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        radio.text:SetPoint("LEFT", radio, "RIGHT", 0, 0)
        radio.text:SetText(themeName:sub(1,1):upper() .. themeName:sub(2))
        
        radio.themeName = themeName
        radio:SetScript("OnClick", function(self)
            local settings = ChatBar:GetSettings()
            settings.buttonTheme = themeName
            -- Uncheck others
            for _, otherRadio in pairs(buttonThemeRadios) do
                if otherRadio ~= self then
                    otherRadio:SetChecked(false)
                end
            end
            ChatBar:Refresh()
        end)
        
        buttonThemeRadios[themeName] = radio
    end
    
    content.buttonThemeRadios = buttonThemeRadios
    
    yOffset = themeYOffset - (#themeOrder * 28) - 20
    
    -- Bar Theme Section (Radio Buttons)
    local barThemeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    barThemeLabel:SetPoint("TOPLEFT", 16, yOffset)
    barThemeLabel:SetText(L.BAR_THEME or "Bar Theme:")
    
    local barThemeRadios = {}
    themeYOffset = yOffset - 24
    
    for i, themeName in ipairs(themeOrder) do
        local radio = CreateFrame("CheckButton", "ChatBarBarTheme" .. themeName, content, "UIRadioButtonTemplate")
        radio:SetPoint("TOPLEFT", 16, themeYOffset - ((i - 1) * 28))
        radio.text = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        radio.text:SetPoint("LEFT", radio, "RIGHT", 0, 0)
        radio.text:SetText(themeName:sub(1,1):upper() .. themeName:sub(2))
        
        radio.themeName = themeName
        radio:SetScript("OnClick", function(self)
            local settings = ChatBar:GetSettings()
            settings.barTheme = themeName
            -- Uncheck others
            for _, otherRadio in pairs(barThemeRadios) do
                if otherRadio ~= self then
                    otherRadio:SetChecked(false)
                end
            end
            ChatBar:Refresh()
        end)
        
        barThemeRadios[themeName] = radio
    end
    
    content.barThemeRadios = barThemeRadios
    
    yOffset = themeYOffset - (#themeOrder * 28) - 20
    
    -- Orientation Section
    local orientationLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientationLabel:SetPoint("TOPLEFT", 16, yOffset)
    orientationLabel:SetText(L.ORIENTATION or "Orientation:")
    
    local orientationHorizontal = CreateFrame("CheckButton", "ChatBarOrientationHorizontal", content, "UIRadioButtonTemplate")
    orientationHorizontal:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", 0, -8)
    orientationHorizontal.text = orientationHorizontal:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    orientationHorizontal.text:SetPoint("LEFT", orientationHorizontal, "RIGHT", 0, 0)
    orientationHorizontal.text:SetText(L.ORIENTATION_HORIZONTAL or "Horizontal")
    
    local orientationVertical = CreateFrame("CheckButton", "ChatBarOrientationVertical", content, "UIRadioButtonTemplate")
    orientationVertical:SetPoint("LEFT", orientationHorizontal, "RIGHT", 120, 0)
    orientationVertical.text = orientationVertical:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    orientationVertical.text:SetPoint("LEFT", orientationVertical, "RIGHT", 0, 0)
    orientationVertical.text:SetText(L.ORIENTATION_VERTICAL or "Vertical")
    
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
    
    -- Font Size Section
    local fontSizeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontSizeLabel:SetPoint("TOPLEFT", 16, yOffset)
    fontSizeLabel:SetText("Font Size:")
    
    local fontSizeSlider = CreateFrame("Slider", "ChatBarFontSizeSlider", content, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", fontSizeLabel, "BOTTOMLEFT", 4, -20)
    fontSizeSlider:SetMinMaxValues(8, 24)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(200)
    
    -- Set slider labels
    _G[fontSizeSlider:GetName() .. "Low"]:SetText("8")
    _G[fontSizeSlider:GetName() .. "High"]:SetText("24")
    _G[fontSizeSlider:GetName() .. "Text"]:SetText("12")
    
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        local settings = ChatBar:GetSettings()
        settings.fontSize = value
        _G[self:GetName() .. "Text"]:SetText(tostring(math.floor(value)))
        ChatBar:Refresh()
    end)
    
    content.fontSizeSlider = fontSizeSlider
    
    yOffset = yOffset - 80
    
    -- Text Position Section
    local textPosLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textPosLabel:SetPoint("TOPLEFT", 16, yOffset)
    textPosLabel:SetText(L.TEXT_POSITION or "Text Position:")
    
    local textPosInside = CreateFrame("CheckButton", "ChatBarTextPosInside", content, "UIRadioButtonTemplate")
    textPosInside:SetPoint("TOPLEFT", textPosLabel, "BOTTOMLEFT", 0, -8)
    textPosInside.text = textPosInside:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    textPosInside.text:SetPoint("LEFT", textPosInside, "RIGHT", 0, 0)
    textPosInside.text:SetText(L.TEXT_POSITION_INSIDE or "Inside buttons")
    
    local textPosAbove = CreateFrame("CheckButton", "ChatBarTextPosAbove", content, "UIRadioButtonTemplate")
    textPosAbove:SetPoint("LEFT", textPosInside, "RIGHT", 120, 0)
    textPosAbove.text = textPosAbove:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    textPosAbove.text:SetPoint("LEFT", textPosAbove, "RIGHT", 0, 0)
    textPosAbove.text:SetText(L.TEXT_POSITION_ABOVE or "Above buttons")
    
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
    flashCheckbox.text = flashCheckbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    flashCheckbox.text:SetPoint("LEFT", flashCheckbox, "RIGHT", 0, 0)
    flashCheckbox.text:SetText(L.FLASH_NOTIFICATIONS_DESC or "Flash buttons on new messages")
    
    flashCheckbox:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.flashNotifications = self:GetChecked()
    end)
    
    content.flashCheckbox = flashCheckbox
    
    yOffset = yOffset - 40
    
    -- Channel Configuration Section
    local channelLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", 16, yOffset)
    channelLabel:SetText(L.ENABLED_CHANNELS or "Enabled Channels:")
    
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
        checkbox.text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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
    numberedLabel:SetText(L.NUMBERED_CHANNELS or "Numbered Channels:")
    
    local numberedEnabled = CreateFrame("CheckButton", "ChatBarNumberedEnabled", content, "UICheckButtonTemplate")
    numberedEnabled:SetPoint("TOPLEFT", numberedLabel, "BOTTOMLEFT", 0, -8)
    numberedEnabled.text = numberedEnabled:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    numberedEnabled.text:SetPoint("LEFT", numberedEnabled, "RIGHT", 0, 0)
    numberedEnabled.text:SetText(L.SHOW_NUMBERED_CHANNELS or "Show numbered channels (General, Trade, LocalDefense, etc.)")
    
    numberedEnabled:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.numberedChannels.enabled = self:GetChecked()
        ChatBar:UpdateButtons()
    end)
    
    content.numberedEnabled = numberedEnabled
    
    -- Lock Position Section
    yOffset = yOffset - 60
    
    local lockLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lockLabel:SetPoint("TOPLEFT", 16, yOffset)
    lockLabel:SetText("Position:")
    
    local lockPosition = CreateFrame("CheckButton", "ChatBarLockPosition", content, "UICheckButtonTemplate")
    lockPosition:SetPoint("TOPLEFT", lockLabel, "BOTTOMLEFT", 0, -8)
    lockPosition.text = lockPosition:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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
    
    -- Add to interface options
    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- Dragonflight+ (10.0+)
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        panel.category = category
        self.settingsCategory = category
    else
        -- Legacy interface options
        InterfaceOptions_AddCategory(panel)
        self.settingsPanel = panel
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
    
    -- Button theme radios
    for themeName, radio in pairs(content.buttonThemeRadios) do
        radio:SetChecked(settings.buttonTheme == themeName)
    end
    
    -- Bar theme radios
    for themeName, radio in pairs(content.barThemeRadios) do
        radio:SetChecked(settings.barTheme == themeName)
    end
    
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
    
    -- Lock position
    content.lockPosition:SetChecked(settings.lockPosition)
    
    -- Font size
    if content.fontSizeSlider then
        content.fontSizeSlider:SetValue(settings.fontSize or 12)
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
end

-- Open settings panel
function Config:OpenSettings()
    if not self.settingsCategory and not self.settingsPanel then
        local L = ns.L
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_SETTINGS_LOADING))
        return
    end
    
    if Settings and Settings.OpenToCategory then
        -- Dragonflight+ (10.0+)
        if self.settingsCategory then
            Settings.OpenToCategory(self.settingsCategory:GetID())
        end
    else
        -- Legacy
        if self.settingsPanel then
            InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
            InterfaceOptionsFrame_OpenToCategory(self.settingsPanel) -- Call twice to fix issue
        end
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
