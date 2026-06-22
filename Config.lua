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
    
    -- Skin Selection Section
    local skinLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    skinLabel:SetPoint("TOPLEFT", 16, yOffset)
    skinLabel:SetText(L.SKIN_SELECTION or "Skin:")
    
    -- Create custom dropdown frame for skin selection
    local skinDropdown = CreateFrame("Frame", "ChatBarSkinDropdown", content, "UIDropDownMenuTemplate")
    skinDropdown:SetPoint("TOPLEFT", skinLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(skinDropdown, 200)
    
    -- Initialize dropdown with available skins
    UIDropDownMenu_Initialize(skinDropdown, function(self, level)
        local settings = ChatBar:GetSettings()
        local skins = ns.Textures:GetAvailableSkins()
        
        for _, skinInfo in ipairs(skins) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = skinInfo.name
            info.value = skinInfo.id
            info.tooltipTitle = skinInfo.name
            info.tooltipText = skinInfo.description .. "\n|cff888888by " .. skinInfo.author .. "|r"
            info.tooltipOnButton = true
            info.func = function(self)
                local settings = ChatBar:GetSettings()
                settings.skinName = skinInfo.id
                UIDropDownMenu_SetSelectedValue(skinDropdown, skinInfo.id)
                UIDropDownMenu_SetText(skinDropdown, skinInfo.name)
                -- Hot-swap skin
                ns.Textures:LoadSkin(skinInfo.id)
                -- Apply skin's default fontSize to settings
                local newSkin = ns.Textures:GetCurrentSkin()
                if newSkin and newSkin.fontSize then
                    settings.fontSize = newSkin.fontSize
                end
                ChatBar:RefreshAllButtons()
                ChatBar:RefreshBarTextures()
                ChatBar:LayoutButtons()
                -- Refresh config UI to show new fontSize
                if ns.Config and ns.Config.panel then
                    ns.Config:RefreshPanel(ns.Config.panel)
                end
            end
            info.checked = (settings.skinName == skinInfo.id)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    content.skinDropdown = skinDropdown
    
    -- Skin description text
    local skinDescription = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    skinDescription:SetPoint("TOPLEFT", skinDropdown, "BOTTOMLEFT", 20, 0)
    skinDescription:SetTextColor(0.6, 0.6, 0.6)
    skinDescription:SetWidth(300)
    skinDescription:SetJustifyH("LEFT")
    content.skinDescription = skinDescription
    
    yOffset = yOffset - 80
    
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
    end)
    
    content.buttonSizeSlider = buttonSizeSlider
    
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
    
    yOffset = yOffset - 30
    
    -- Channel History Cycling Section
    local historyCheckbox = CreateFrame("CheckButton", "ChatBarChannelHistory", content, "UICheckButtonTemplate")
    historyCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    historyCheckbox.text = historyCheckbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    historyCheckbox.text:SetPoint("LEFT", historyCheckbox, "RIGHT", 0, 0)
    -- Constrain width so long (localized) labels wrap instead of running off-screen.
    historyCheckbox.text:SetWidth(500)
    historyCheckbox.text:SetJustifyH("LEFT")
    historyCheckbox.text:SetText(L.CHANNEL_HISTORY_DESC or "Enable channel history cycling (assign keys in Key Bindings)")
    
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
    hideLoadedCheckbox.text = hideLoadedCheckbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hideLoadedCheckbox.text:SetPoint("LEFT", hideLoadedCheckbox, "RIGHT", 0, 0)
    hideLoadedCheckbox.text:SetText(L.HIDE_LOADED_MESSAGE or "Hide loaded message in chat")
    
    hideLoadedCheckbox:SetScript("OnClick", function(self)
        local settings = ChatBar:GetSettings()
        settings.hideLoadedMessage = self:GetChecked()
    end)
    
    content.hideLoadedCheckbox = hideLoadedCheckbox
    
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
        Config:BuildNumberedChannelCheckboxes(content)
    end)
    
    content.numberedEnabled = numberedEnabled
    
    -- Sub-label for the per-channel filter list
    local numberedFilterLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    numberedFilterLabel:SetPoint("TOPLEFT", numberedEnabled, "BOTTOMLEFT", 20, -10)
    numberedFilterLabel:SetText(L.NUMBERED_CHANNEL_FILTERS or "Filter individual channels:")
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
    numberedNoneLabel:SetText(L.NUMBERED_CHANNEL_NONE or "No numbered channels currently joined.")
    numberedNoneLabel:Hide()
    content.numberedNoneLabel = numberedNoneLabel
    
    -- Lock Position Section — anchored relative to the dynamic filter section so it
    -- repositions automatically when the filter list grows or shrinks.
    local lockLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lockLabel:SetPoint("TOPLEFT", numberedFilterSection, "BOTTOMLEFT", -4, -20)
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
    
    -- Live-refresh the per-channel filter list whenever joined channels change.
    local channelUpdateListener = CreateFrame("Frame")
    channelUpdateListener:RegisterEvent("CHANNEL_UI_UPDATE")
    channelUpdateListener:SetScript("OnEvent", function()
        if panel:IsVisible() then
            Config:BuildNumberedChannelCheckboxes(panel.content)
        end
    end)
    
    -- Add to interface options using modern Settings API (WoW 12.0.1+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        panel.category = category
        self.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        -- Legacy fallback for clients where Settings API registration differs.
        InterfaceOptions_AddCategory(panel)
        self.settingsCategory = panel
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
    
    -- Skin dropdown
    if content.skinDropdown then
        local skinName = settings.skinName or "Default"
        local skin = ns.SkinRegistry and ns.SkinRegistry[skinName]
        UIDropDownMenu_SetSelectedValue(content.skinDropdown, skinName)
        UIDropDownMenu_SetText(content.skinDropdown, skin and skin.name or skinName)
        
        -- Update description text
        if content.skinDescription and skin then
            content.skinDescription:SetText(skin.description .. " | by " .. (skin.author or "Unknown"))
        end
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

        -- Create the label FontString the first time this pool frame is used.
        if not cb.text then
            cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            cb.text:SetPoint("LEFT", cb, "RIGHT", 0, 0)
        end
        cb.text:SetText(ch.name)

        if ch.disabled then
            cb.text:SetTextColor(0.5, 0.5, 0.5)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(L.NUMBERED_CHANNEL_INACTIVE or "Currently inactive")
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
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.panel)
        InterfaceOptionsFrame_OpenToCategory(self.panel)
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
