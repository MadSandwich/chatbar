-- ChatBar: Quick chat channel switcher addon
-- Main addon file

local addonName, ns = ...

-- Create addon object
local ChatBar = {}
ns.ChatBar = ChatBar

-- Version constant
ChatBar.VERSION = "2.2.4"

-- Default settings
ns.Defaults = {
    version = 2,
    profileMode = "account", -- "account" or "character"
    skinName = "Default", -- Skin folder name
    orientation = "horizontal", -- "horizontal" or "vertical"
    barVisible = true,
    lockPosition = false,
    barPosition = nil, -- Saved position {point, relativePoint, x, y}
    fontSize = 12, -- Button text font size
    buttonSize = 20, -- Button size (increased for better texture visibility)
    textPosition = "inside", -- "inside" or "above" - where to display channel letters
    keybind = nil,
    flashNotifications = true, -- Flash buttons on new messages
    flashDuration = 3, -- Duration of flash notifications in seconds
    hideLoadedMessage = true, -- Hide addon loaded message in chat
    
    -- Channel configuration
    channels = {
        -- Always available
        SAY = { enabled = true, order = 1 },
        YELL = { enabled = true, order = 2 },
        EMOTE = { enabled = false, order = 3 },
        WHISPER = { enabled = false, order = 4 },
        BN_WHISPER = { enabled = false, order = 5 },
        
        -- Group channels
        PARTY = { enabled = true, order = 6 },
        RAID = { enabled = true, order = 7 },
        RAID_WARNING = { enabled = true, order = 8 },
        INSTANCE_CHAT = { enabled = true, order = 9 },
        
        -- Guild channels
        GUILD = { enabled = true, order = 10 },
        OFFICER = { enabled = true, order = 11 },
        
        -- PvP channels
        BATTLEGROUND = { enabled = true, order = 12 },
    },
    
    -- Numbered channels (General, Trade, LocalDefense, etc.)
    numberedChannels = {
        enabled = true,
        filters = {} -- Empty means show all, otherwise specific channel names
    }
}

-- Skin registry (populated by skin.lua files)
ns.SkinRegistry = ns.SkinRegistry or {}

-- Channel info with localization keys
ns.ChannelInfo = {
    SAY = { labelKey = "CHAT_SAY", command = "SAY", requiresTarget = false },
    YELL = { labelKey = "CHAT_YELL", command = "YELL", requiresTarget = false },
    EMOTE = { labelKey = "CHAT_EMOTE", command = "EMOTE", requiresTarget = false },
    WHISPER = { labelKey = "CHAT_WHISPER", command = "WHISPER", requiresTarget = true },
    BN_WHISPER = { labelKey = "CHAT_BN_WHISPER", command = "BN_WHISPER", requiresTarget = true },
    PARTY = { labelKey = "CHAT_PARTY", command = "PARTY", requiresTarget = false },
    RAID = { labelKey = "CHAT_RAID", command = "RAID", requiresTarget = false },
    RAID_WARNING = { labelKey = "CHAT_RAID_WARNING", command = "RAID_WARNING", requiresTarget = false },
    INSTANCE_CHAT = { labelKey = "CHAT_INSTANCE", command = "INSTANCE_CHAT", requiresTarget = false },
    GUILD = { labelKey = "CHAT_GUILD", command = "GUILD", requiresTarget = false },
    OFFICER = { labelKey = "CHAT_OFFICER", command = "OFFICER", requiresTarget = false },
    BATTLEGROUND = { labelKey = "CHAT_BATTLEGROUND", command = "BATTLEGROUND", requiresTarget = false },
}

-- Local references
local buttonPool = {}
local activeButtons = {}
local currentChatFrame = nil
local barFrame = nil

local function OpenChatWithFallback(text, chatFrame)
    if ChatFrameUtil and ChatFrameUtil.OpenChat then
        local editBox = ChatFrameUtil.OpenChat(text or "", chatFrame)
        if editBox then
            return editBox
        end
    end

    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(text or "", chatFrame)
        return chatFrame and chatFrame.editBox
    end

    return chatFrame and chatFrame.editBox
end

local function RefreshEditBoxHeader(editBox)
    if not editBox then return end

    if editBox.UpdateHeader then
        editBox:UpdateHeader()
    elseif ChatEdit_UpdateHeader then
        ChatEdit_UpdateHeader(editBox)
    end
end

-- Get active settings based on profile mode
function ChatBar:GetSettings()
    local db = ns.db
    if db.profileMode == "character" and ns.charDB then
        return ns.charDB
    end
    return db
end

-- Initialize addon UI
function ChatBar:Initialize()
    -- SavedVariables are already initialized in ADDON_LOADED
    -- Just setup UI
    self:CreateBarFrame()
    self:SetupChatFrameHooks()
    self:RegisterEvents()
    
    currentChatFrame = ChatFrame1
end

-- Deep copy table
function ChatBar:CopyTable(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for key, value in pairs(src) do
        copy[key] = self:CopyTable(value)
    end
    return copy
end

-- Merge defaults into existing table
function ChatBar:MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = self:CopyTable(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            self:MergeDefaults(target[key], value)
        end
    end
end

-- Create main bar frame
function ChatBar:CreateBarFrame()
    if barFrame then return end
    
    -- Load the default skin
    local settings = self:GetSettings()
    ns.Textures:LoadSkin(settings.skinName)
    
    barFrame = CreateFrame("Frame", "ChatBarFrame", UIParent)
    barFrame:SetFrameStrata("MEDIUM")
    barFrame:SetSize(100, 40) -- Will be resized based on buttons
    
    -- Create bar textures using skin system
    ns.Textures:CreateBarTextures(barFrame)
    
    -- Set initial position (will be overridden by saved position if exists)
    if settings.barPosition then
        barFrame:SetPoint(settings.barPosition.point, UIParent, settings.barPosition.relativePoint, settings.barPosition.x, settings.barPosition.y)
    else
        -- Default: Above chat frame tabs (chat tabs are about 20px tall)
        barFrame:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 24)
    end
    
    -- Make draggable
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")
    barFrame:SetScript("OnDragStart", function(self)
        local settings = ChatBar:GetSettings()
        if not settings.lockPosition then
            self:StartMoving()
        end
    end)
    barFrame:SetScript("OnDragStop", function(self)
        local settings = ChatBar:GetSettings()
        if not settings.lockPosition then
            self:StopMovingOrSizing()
            -- Save position
            local point, _, relativePoint, x, y = self:GetPoint()
            settings.barPosition = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y
            }
        end
    end)
    
    barFrame:Show()
end

-- Refresh bar textures from current skin
function ChatBar:RefreshBarTextures()
    if not barFrame then return end
    ns.Textures:RefreshBarTextures(barFrame)
end

-- Setup chat frame hooks
function ChatBar:SetupChatFrameHooks()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame.editBox then
            chatFrame.editBox:HookScript("OnEditFocusGained", function(editBox)
                self:OnChatFrameFocusGained(chatFrame)
            end)
        end
    end
end

-- Handle chat frame focus change
function ChatBar:OnChatFrameFocusGained(chatFrame)
    currentChatFrame = chatFrame
    self:PositionBar()
end

-- Position bar relative to active chat frame
function ChatBar:PositionBar()
    if not barFrame then return end
    
    local settings = self:GetSettings()
    
    -- Only reposition if position is unlocked and no custom position saved
    if settings.lockPosition or settings.barPosition then
        -- Keep current position
        return
    end
    
    if not currentChatFrame then return end
    
    -- Auto-position relative to chat frame (above tabs)
    barFrame:ClearAllPoints()
    
    if settings.orientation == "horizontal" then
        barFrame:SetPoint("BOTTOMLEFT", currentChatFrame, "TOPLEFT", 0, 24)
    else -- vertical
        barFrame:SetPoint("TOPLEFT", currentChatFrame, "TOPRIGHT", 4, -24)
    end
end

-- Register events using self[event] pattern
function ChatBar:RegisterEvents()
    if not barFrame then return end
    
    barFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    barFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    barFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    barFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    barFrame:RegisterEvent("CHANNEL_UI_UPDATE")
    barFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    barFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
    
    -- Chat message events for flash notifications (always registered)
    barFrame:RegisterEvent("CHAT_MSG_SAY")
    barFrame:RegisterEvent("CHAT_MSG_YELL")
    barFrame:RegisterEvent("CHAT_MSG_EMOTE")
    barFrame:RegisterEvent("CHAT_MSG_WHISPER")
    barFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
    barFrame:RegisterEvent("CHAT_MSG_PARTY")
    barFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    barFrame:RegisterEvent("CHAT_MSG_RAID")
    barFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    barFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    barFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
    barFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
    barFrame:RegisterEvent("CHAT_MSG_GUILD")
    barFrame:RegisterEvent("CHAT_MSG_OFFICER")
    barFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    
    barFrame:SetScript("OnEvent", function(frame, event, ...)
        if ChatBar[event] then
            ChatBar[event](ChatBar, ...)
        else
            -- Handle chat message events for flashing
            ChatBar:HandleChatMessageEvent(event, ...)
        end
    end)
end

-- Individual event handlers
function ChatBar:PLAYER_ENTERING_WORLD()
    self:UpdateButtons()
    currentChatFrame = ChatFrame1
    self:PositionBar()
end

function ChatBar:GROUP_ROSTER_UPDATE()
    self:UpdateButtons()
end

function ChatBar:PLAYER_GUILD_UPDATE()
    self:UpdateButtons()
end

function ChatBar:GUILD_ROSTER_UPDATE()
    self:UpdateButtons()
end

function ChatBar:CHANNEL_UI_UPDATE()
    self:UpdateButtons()
end

function ChatBar:ZONE_CHANGED_NEW_AREA()
    self:UpdateButtons()
end

function ChatBar:UPDATE_CHAT_WINDOWS()
    self:PositionBar()
end

-- Handle chat message events for flash notifications
function ChatBar:HandleChatMessageEvent(event, ...)
    local settings = self:GetSettings()
    if not settings.flashNotifications then return end
    
    -- Get sender GUID (12th parameter)
    local playerGUID = select(12, ...)
    
    -- Check if message is from the player (ignore own messages)
    -- Use pcall to safely handle "secret values" in WoW's taint system
    local myGUID = UnitGUID("player")
    local success, isOwnMessage = pcall(function()
        return playerGUID == myGUID
    end)

    if success and isOwnMessage then
        return -- Don't flash for own messages
    end
    
    -- Extract channel type from event name (strip "CHAT_MSG_" prefix)
    local channelType
    
    if event == "CHAT_MSG_CHANNEL" then
        -- For numbered channels, get the channel number from parameters
        local chanNum = select(8, ...)
        if type(chanNum) == "number" then
            -- Find button for this numbered channel
            for _, button in pairs(activeButtons) do
                if button.channelData and button.channelData.isNumbered and button.channelData.id == chanNum then
                    self:FlashButton(button)
                    return
                end
            end
        end
        return
    else
        -- For regular channels, strip "CHAT_MSG_" prefix to get channel type
        channelType = event:sub(10) -- Remove "CHAT_MSG_" (9 chars + 1)
        
        -- Map event suffixes to our channel types
        if channelType == "PARTY_LEADER" then
            channelType = "PARTY"
        elseif channelType == "RAID_LEADER" then
            channelType = "RAID"
        elseif channelType == "INSTANCE_CHAT_LEADER" then
            channelType = "INSTANCE_CHAT"
        end
    end
    
    if not channelType then return end
    
    -- Find button for this channel type
    for _, button in pairs(activeButtons) do
        if button.channelData and button.channelData.channelType == channelType then
            self:FlashButton(button)
            break
        end
    end
end

function ChatBar:FlashButton(button)
    if not button then return end
    
    local settings = self:GetSettings()
    local duration = settings.flashDuration or 3
    
    -- Stop any existing flash
    if button.isFlashing then
        self:StopFlashButton(button)
    end
    
    -- Start flash using Textures module
    ns.Textures:StartFlash(button)
    button.flashStopTime = GetTime() + duration
    
    -- Set up timer to stop flashing after duration
    if not button.flashTimer then
        button.flashTimer = C_Timer.NewTicker(0.1, function()
            if button.flashStopTime and GetTime() >= button.flashStopTime then
                ChatBar:StopFlashButton(button)
            end
        end)
    end
end

function ChatBar:StopFlashButton(button)
    if not button then return end
    
    button.flashStopTime = nil
    
    -- Stop flash using Textures module
    ns.Textures:StopFlash(button)
    
    -- Cancel timer if it exists
    if button.flashTimer then
        button.flashTimer:Cancel()
        button.flashTimer = nil
    end
end

-- Check if a channel is available
function ChatBar:IsChannelAvailable(channelType)
    if channelType == "SAY" or channelType == "YELL" or channelType == "EMOTE" then
        return true
    end
    
    if channelType == "WHISPER" then
        return true -- Always available but needs target
    end
    
    if channelType == "PARTY" then
        return IsInGroup() and not IsInRaid()
    end
    
    if channelType == "RAID" or channelType == "RAID_WARNING" then
        return IsInRaid()
    end
    
    if channelType == "INSTANCE_CHAT" then
        return IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
    end
    
    if channelType == "GUILD" then
        return IsInGuild()
    end
    
    if channelType == "OFFICER" then
        return IsInGuild() and C_GuildInfo.CanSpeakInGuildChat()
    end
    
    if channelType == "BATTLEGROUND" then
        return C_PvP.IsActiveBattlefield()
    end
    
    return false
end

-- Get numbered channels
function ChatBar:GetNumberedChannels()
    local channels = {}
    local settings = self:GetSettings()
    
    if not settings.numberedChannels.enabled then
        return channels
    end
    
    local channelList = { GetChannelList() }
    
    for i = 1, #channelList, 3 do
        local id = channelList[i]
        local name = channelList[i + 1]
        
        if id and name then
            -- Apply filters if any
            local filters = settings.numberedChannels.filters
            local showChannel = true
            
            if filters and next(filters) then
                showChannel = filters[name] == true
            end
            
            if showChannel then
                table.insert(channels, {
                    id = id,
                    name = name,
                    channelType = "CHANNEL",
                    order = 100 + id,
                    isNumbered = true
                })
            end
        end
    end
    
    return channels
end

-- Update buttons based on available channels
function ChatBar:UpdateButtons()
    if not barFrame then return end
    
    local settings = self:GetSettings()
    
    -- Hide all existing buttons
    for _, button in pairs(activeButtons) do
        button:Hide()
    end
    wipe(activeButtons)
    
    -- Build list of visible channels
    local visibleChannels = {}
    
    -- Add standard channels
    for channelType, config in pairs(settings.channels) do
        if config.enabled and self:IsChannelAvailable(channelType) then
            table.insert(visibleChannels, {
                channelType = channelType,
                order = config.order,
                isNumbered = false
            })
        end
    end
    
    -- Add numbered channels
    local numberedChannels = self:GetNumberedChannels()
    for _, channel in ipairs(numberedChannels) do
        table.insert(visibleChannels, channel)
    end
    
    -- Sort by order
    table.sort(visibleChannels, function(a, b) return a.order < b.order end)
    
    -- Create/show buttons
    for i, channelData in ipairs(visibleChannels) do
        local button = self:GetOrCreateButton(i)
        self:SetupButton(button, channelData)
        table.insert(activeButtons, button)
        button:Show()
    end
    
    -- Layout buttons
    self:LayoutButtons()
    
    -- Update bar visibility
    barFrame:SetShown(settings.barVisible and #activeButtons > 0)
end

-- Get or create a button from pool
function ChatBar:GetOrCreateButton(index)
    if buttonPool[index] then
        return buttonPool[index]
    end
    
    local button = CreateFrame("Button", "ChatBarButton" .. index, barFrame)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Create font string with standard WoW font (supports all locales including Cyrillic)
    local text = button:CreateFontString(nil, "OVERLAY")
    button.text = text
    text:SetFont(STANDARD_TEXT_FONT, 12, "")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)
    
    -- Flash state tracking (animation created by Textures module)
    button.isFlashing = false
    button.flashStopTime = nil
    
    -- Scripts
    button:SetScript("OnClick", function(self, mouseButton)
        ChatBar:OnButtonClick(self, mouseButton)
    end)
    
    button:SetScript("OnEnter", function(self)
        ChatBar:OnButtonEnter(self)
    end)
    
    button:SetScript("OnLeave", function(self)
        ChatBar:OnButtonLeave(self)
    end)
    
    buttonPool[index] = button
    return button
end

-- Setup button for a channel
function ChatBar:SetupButton(button, channelData)
    local L = ns.L
    local settings = self:GetSettings()
    local skin = ns.Textures:GetCurrentSkin()
    
    button.channelData = channelData
    local buttonSize = settings.buttonSize or 24
    button:SetSize(buttonSize, buttonSize)
    
    -- Get chat color for this channel
    local chatType = channelData.isNumbered and "CHANNEL" or channelData.channelType
    local chatColor = ChatTypeInfo[chatType]
    
    -- Check if we need to recreate textures
    local sizeChanged = button.textureSize and button.textureSize ~= buttonSize
    local skinShape = skin.shape or "square"
    local shapeChanged = button.currentShape and button.currentShape ~= skinShape
    local currentSkinName = settings.skinName or "Default"
    local skinChanged = button.currentSkin and button.currentSkin ~= currentSkinName
    
    if sizeChanged or shapeChanged or skinChanged or not button.bgTexture then
        -- Clean up old textures
        ns.Textures:CleanupButton(button)
        
        -- Create new textures using skin system
        ns.Textures:CreateButtonLayers(button, buttonSize)
        
        button.currentShape = skinShape
        button.currentSkin = currentSkinName
    elseif button.textureSize ~= buttonSize then
        -- Just resize existing textures
        ns.Textures:ResizeButtonTextures(button, buttonSize)
    end
    
    -- Apply channel color to textures
    if chatColor then
        ns.Textures:ApplyChannelColor(button, chatColor)
    end
    
    -- Apply font settings using standard WoW font (supports all locales)
    -- settings.fontSize is updated on skin switch to skin's default
    local fontSize = settings.fontSize or skin.fontSize or 12
    button.text:SetFont(STANDARD_TEXT_FONT, fontSize, "")
    
    -- Apply text shadow based on skin
    if skin.textShadow then
        button.text:SetShadowColor(0, 0, 0, 1)
        button.text:SetShadowOffset(1, -1)
    else
        button.text:SetShadowOffset(0, 0)
    end
    
    -- Position text based on settings
    button.text:ClearAllPoints()
    if settings.textPosition == "above" then
        button.text:SetPoint("BOTTOM", button, "TOP", 0, 2)
    else
        button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    
    -- Set text color (use channel color for visibility)
    if chatColor then
        -- Use slightly brightened channel color for text
        local brightness = 1.3
        button.text:SetTextColor(
            math.min(chatColor.r * brightness, 1),
            math.min(chatColor.g * brightness, 1),
            math.min(chatColor.b * brightness, 1),
            1
        )
    else
        button.text:SetTextColor(1, 1, 1, 1)
    end
    button.text:Show()
    
    -- Set button text
    if channelData.isNumbered then
        button.text:SetText(tostring(channelData.id))
    else
        local info = ns.ChannelInfo[channelData.channelType]
        if info and info.labelKey then
            local label = L[info.labelKey]
            local firstChar = "?"
            if label and type(label) == "string" and #label > 0 then
                -- Extract first UTF-8 character
                firstChar = (label:match("^([%z\1-\127\194-\244][\128-\191]*)") or "?"):upper()
            end
            button.text:SetText(firstChar)
        else
            button.text:SetText("?")
        end
    end
    
    -- Set enabled state
    local available = channelData.isNumbered or self:IsChannelAvailable(channelData.channelType)
    button:SetEnabled(available)
    button:SetAlpha(available and 1.0 or 0.5)
end

-- Layout buttons based on orientation
function ChatBar:LayoutButtons()
    if #activeButtons == 0 then return end
    
    local settings = self:GetSettings()
    local skin = ns.Textures:GetCurrentSkin()
    
    local padding = skin.barPadding or 6
    local spacing = skin.buttonSpacing or 1
    local buttonSize = settings.buttonSize or 24
    
    if settings.orientation == "horizontal" then
        -- Horizontal layout
        local totalWidth = (buttonSize * #activeButtons) + (spacing * (#activeButtons - 1)) + (padding * 2)
        local totalHeight = buttonSize + (padding * 2)
        
        barFrame:SetSize(totalWidth, totalHeight)
        
        for i, button in ipairs(activeButtons) do
            button:ClearAllPoints()
            local xOffset = padding + ((i - 1) * (buttonSize + spacing))
            button:SetPoint("LEFT", barFrame, "LEFT", xOffset, 0)
        end
    else
        -- Vertical layout
        local totalWidth = buttonSize + (padding * 2)
        local totalHeight = (buttonSize * #activeButtons) + (spacing * (#activeButtons - 1)) + (padding * 2)
        
        barFrame:SetSize(totalWidth, totalHeight)
        
        for i, button in ipairs(activeButtons) do
            button:ClearAllPoints()
            local yOffset = -padding - ((i - 1) * (buttonSize + spacing))
            button:SetPoint("TOP", barFrame, "TOP", 0, yOffset)
        end
    end
end

-- Button click handler
function ChatBar:OnButtonClick(button, mouseButton)
    if not currentChatFrame then return end
    
    -- Stop flashing when clicked
    self:StopFlashButton(button)
    
    -- Preserve current message text if chat is open
    local preservedText = ""
    local editBox = currentChatFrame.editBox
    if editBox and editBox:IsShown() then
        preservedText = editBox:GetText() or ""
    end
    
    local channelData = button.channelData
    
    if channelData.isNumbered then
        -- Numbered channel - open chat first, then set channel
        local editBox = OpenChatWithFallback(preservedText, currentChatFrame)
        if editBox then
            if editBox.SetChatType then
                editBox:SetChatType("CHANNEL")
            elseif editBox.SetAttribute then
                editBox:SetAttribute("chatType", "CHANNEL")
            end

            if editBox.SetChannelTarget then
                editBox:SetChannelTarget(channelData.id)
            elseif editBox.SetAttribute then
                editBox:SetAttribute("channelTarget", channelData.id)
            end

            RefreshEditBoxHeader(editBox)
            -- Restore cursor position to end of preserved text
            if preservedText ~= "" then
                editBox:SetCursorPosition(#preservedText)
            end
        end
    else
        -- Standard channel
        local info = ns.ChannelInfo[channelData.channelType]
        if info then
            if info.requiresTarget and (channelData.channelType == "WHISPER" or channelData.channelType == "BN_WHISPER") then
                -- For whisper, open chat with /w command
                local cmd = channelData.channelType == "BN_WHISPER" and "/bw " or "/w "
                -- Append preserved text after the command
                OpenChatWithFallback(cmd .. preservedText, currentChatFrame)
                return
            else
                -- Open chat and set channel type using proper API
                local editBox = OpenChatWithFallback(preservedText, currentChatFrame)
                if editBox then
                    if editBox.SetChatType then
                        editBox:SetChatType(info.command)
                    elseif editBox.SetAttribute then
                        editBox:SetAttribute("chatType", info.command)
                    end

                    RefreshEditBoxHeader(editBox)
                    -- Restore cursor position to end of preserved text
                    if preservedText ~= "" then
                        editBox:SetCursorPosition(#preservedText)
                    end
                end
            end
        end
    end
end

-- Button enter handler (tooltip)
function ChatBar:OnButtonEnter(button)
    local L = ns.L
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    
    local channelData = button.channelData
    
    if channelData.isNumbered then
        GameTooltip:SetText(channelData.name)
        GameTooltip:AddLine(L.TOOLTIP_CHANNEL .. " " .. channelData.id, 1, 1, 1)
    else
        local info = ns.ChannelInfo[channelData.channelType]
        if info then
            local label = L[info.labelKey] or info.labelKey
            GameTooltip:SetText(label .. " " .. L.TOOLTIP_CHAT)
            GameTooltip:AddLine(L.TOOLTIP_CLICK_SWITCH, 0.7, 0.7, 0.7)
        end
    end
    
    GameTooltip:Show()
end

-- Button leave handler
function ChatBar:OnButtonLeave(button)
    GameTooltip:Hide()
end

-- Toggle bar visibility
function ChatBar:ToggleBar()
    local L = ns.L
    local settings = self:GetSettings()
    settings.barVisible = not settings.barVisible
    
    if barFrame then
        barFrame:SetShown(settings.barVisible and #activeButtons > 0)
    end
    
    print(string.format("%s: %s %s", L.ADDON_NAME, L.MSG_BAR_TOGGLED, settings.barVisible and L.MSG_BAR_SHOWN or L.MSG_BAR_HIDDEN))
end

-- Refresh all button textures (for skin hot-swap)
function ChatBar:RefreshAllButtons()
    for _, button in pairs(activeButtons) do
        ns.Textures:RefreshButtonTextures(button)
        -- Reapply channel color
        if button.channelData then
            local chatType = button.channelData.isNumbered and "CHANNEL" or button.channelData.channelType
            local chatColor = ChatTypeInfo[chatType]
            if chatColor then
                ns.Textures:ApplyChannelColor(button, chatColor)
            end
        end
    end
end

-- Refresh the addon (reapply skin, rebuild buttons)
function ChatBar:Refresh()
    self:RefreshBarTextures()
    self:UpdateButtons()
    self:PositionBar()
end

-- Slash command handler
function ChatBar:HandleSlashCommand(msg)
    local L = ns.L
    
    -- Check if addon is initialized
    if not ns.db then
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_STILL_LOADING))
        return
    end
    
    msg = msg:lower():trim()
    
    if msg == "toggle" then
        self:ToggleBar()
    elseif msg == "show" then
        local settings = self:GetSettings()
        settings.barVisible = true
        if barFrame then
            barFrame:Show()
        end
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_BAR_SHOWN))
    elseif msg == "hide" then
        local settings = self:GetSettings()
        settings.barVisible = false
        if barFrame then
            barFrame:Hide()
        end
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_BAR_HIDDEN))
    elseif msg == "reset" then
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_RESET))
        local profileMode = ns.db.profileMode
        if profileMode == "character" then
            ChatBarCharDB = self:CopyTable(ns.Defaults)
            ns.charDB = ChatBarCharDB
            -- Apply skin's default fontSize after reset
            local skin = ns.SkinRegistry[ns.charDB.skinName or "Default"]
            if skin and skin.fontSize then
                ns.charDB.fontSize = skin.fontSize
            end
        else
            ChatBarDB = self:CopyTable(ns.Defaults)
            ns.db = ChatBarDB
            -- Apply skin's default fontSize after reset
            local skin = ns.SkinRegistry[ns.db.skinName or "Default"]
            if skin and skin.fontSize then
                ns.db.fontSize = skin.fontSize
            end
        end
        self:Refresh()
        -- Refresh config UI to show new values
        if ns.Config and ns.Config.panel then
            ns.Config:RefreshPanel(ns.Config.panel)
        end
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_RESET_COMPLETE))
    elseif msg == "help" or msg == "?" then
        print(string.format("%s v%s - %s", L.ADDON_NAME, self.VERSION, L.CMD_HELP_HEADER))
        print(string.format("  |cffff8800/chatbar|r - %s", L.CMD_OPEN_SETTINGS))
        print(string.format("  |cffff8800/chatbar toggle|r - %s", L.CMD_TOGGLE))
        print(string.format("  |cffff8800/chatbar show|r - %s", L.CMD_SHOW))
        print(string.format("  |cffff8800/chatbar hide|r - %s", L.CMD_HIDE))
        print(string.format("  |cffff8800/chatbar reset|r - %s", L.CMD_RESET))
        print(string.format("  |cffff8800/chatbar help|r - %s", L.CMD_HELP))
    else
        -- Open settings panel
        if ns.Config then
            ns.Config:OpenSettings()
        end
    end
end

-- Keybinding functions
function ChatBar:SwitchToChannel(channelType)
    local L = ns.L
    local info = ns.ChannelInfo[channelType]
    if not info then return end
    
    -- Check if channel is available
    if not self:IsChannelAvailable(channelType) then
        print(string.format("%s: Channel %s not available", L.ADDON_NAME, channelType))
        return
    end
    
    -- Switch to channel
    local editBox = ChatEdit_ChooseBoxForSend()
    if editBox then
        ChatEdit_SetLastActiveWindow(editBox)
        RefreshEditBoxHeader(editBox)
        
        local chatType = info.command
        if editBox.SetChatType then
            editBox:SetChatType(chatType)
        elseif editBox.SetAttribute then
            editBox:SetAttribute("chatType", chatType)
        end

        RefreshEditBoxHeader(editBox)
        
        if not editBox:IsShown() then
            ChatEdit_ActivateChat(editBox)
        end
    end
end

-- Initialize on ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        local L = ns.L
        
        -- Initialize SavedVariables FIRST
        ns.db = ChatBarDB or {}
        if not ChatBarDB then
            ChatBarDB = ChatBar:CopyTable(ns.Defaults)
            ns.db = ChatBarDB
            -- Apply skin's default fontSize on first install
            local skin = ns.SkinRegistry[ns.db.skinName or "Default"]
            if skin and skin.fontSize then
                ns.db.fontSize = skin.fontSize
            end
        else
            -- Merge with defaults for missing keys
            ChatBar:MergeDefaults(ns.db, ns.Defaults)
        end
        
        ns.charDB = ChatBarCharDB or {}
        if not ChatBarCharDB then
            ChatBarCharDB = ChatBar:CopyTable(ns.Defaults)
            ns.charDB = ChatBarCharDB
            -- Apply skin's default fontSize on first install
            local skin = ns.SkinRegistry[ns.charDB.skinName or "Default"]
            if skin and skin.fontSize then
                ns.charDB.fontSize = skin.fontSize
            end
        else
            ChatBar:MergeDefaults(ns.charDB, ns.Defaults)
        end
        
        -- Now initialize UI
        ChatBar:Initialize()
        
        -- Initialize Config
        if ns.Config then
            ns.Config:Initialize()
        end
        
        -- Print loaded message if not hidden
        local settings = ChatBar:GetSettings()
        if not settings.hideLoadedMessage then
            print(string.format("%s v%s %s", L.ADDON_NAME, ChatBar.VERSION, L.ADDON_LOADED))
        end
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- WoW keybindings execute in global scope and cannot access addon namespace directly
function ChatBar_ToggleBar()
    if ns and ns.ChatBar then
        ns.ChatBar:ToggleBar()
    end
end

function ChatBar_SwitchToChannel(channelType)
    if ns and ns.ChatBar then
        ns.ChatBar:SwitchToChannel(channelType)
    end
end
