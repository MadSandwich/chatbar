-- ChatBar: Quick chat channel switcher addon
-- Main addon file

local addonName, ns = ...

-- Create addon object
local ChatBar = {}
ns.ChatBar = ChatBar

-- Constants
ChatBar.VERSION = "1.0.0"

-- Default settings
ns.Defaults = {
    version = 1,
    profileMode = "account", -- "account" or "character"
    buttonTheme = "classic",
    barTheme = "classic",
    orientation = "horizontal", -- "horizontal" or "vertical"
    barVisible = true,
    lockPosition = false,
    barPosition = nil, -- Saved position {point, relativePoint, x, y}
    fontSize = 12, -- Button text font size
    keybind = nil,
    
    -- Channel configuration
    channels = {
        -- Always available
        SAY = { enabled = true, order = 1 },
        YELL = { enabled = true, order = 2 },
        EMOTE = { enabled = true, order = 3 },
        WHISPER = { enabled = true, order = 4 },
        
        -- Group channels
        PARTY = { enabled = true, order = 5 },
        RAID = { enabled = true, order = 6 },
        RAID_WARNING = { enabled = true, order = 7 },
        INSTANCE_CHAT = { enabled = true, order = 8 },
        
        -- Guild channels
        GUILD = { enabled = true, order = 9 },
        OFFICER = { enabled = true, order = 10 },
        
        -- PvP channels
        BATTLEGROUND = { enabled = true, order = 11 },
    },
    
    -- Numbered channels (General, Trade, LocalDefense, etc.)
    numberedChannels = {
        enabled = true,
        filters = {} -- Empty means show all, otherwise specific channel names
    }
}

-- Theme presets
ns.Themes = {
    buttons = {
        classic = {
            size = 24,
            spacing = 1,
            font = "GameFontNormalSmall",
            useProgrammaticTextures = true,
            normalColor = { r = 0.25, g = 0.25, b = 0.25, a = 0.8 },
            pushedColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.9 },
            highlightColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.5 },
            borderSize = 1,
            borderColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
            useChatColors = true
        },
        modern = {
            size = 24,
            spacing = 1,
            font = "GameFontNormal",
            useProgrammaticTextures = true,
            normalColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.9 },
            pushedColor = { r = 0.05, g = 0.05, b = 0.05, a = 1 },
            highlightColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 },
            borderSize = 2,
            borderColor = { r = 0.35, g = 0.35, b = 0.35, a = 1 },
            useChatColors = true
        },
        minimal = {
            size = 24,
            spacing = 1,
            font = "GameFontNormalSmall",
            useProgrammaticTextures = true,
            normalColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.6 },
            pushedColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.8 },
            highlightColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.4 },
            borderSize = 0,
            useChatColors = true
        }
    },
    
    bars = {
        classic = {
            backdrop = {
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            },
            bgColor = { r = 0, g = 0, b = 0, a = 0.8 },
            borderColor = { r = 1, g = 1, b = 1, a = 1 },
            padding = 6
        },
        modern = {
            backdrop = {
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                edgeSize = 2,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            },
            bgColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
            borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
            padding = 4
        },
        minimal = {
            backdrop = {
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = nil,
                tile = false,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            },
            bgColor = { r = 0, g = 0, b = 0, a = 0.5 },
            borderColor = { r = 0, g = 0, b = 0, a = 0 },
            padding = 2
        }
    }
}

-- Channel info with localization keys
ns.ChannelInfo = {
    SAY = { labelKey = "CHAT_SAY", command = "SAY", requiresTarget = false },
    YELL = { labelKey = "CHAT_YELL", command = "YELL", requiresTarget = false },
    EMOTE = { labelKey = "CHAT_EMOTE", command = "EMOTE", requiresTarget = false },
    WHISPER = { labelKey = "CHAT_WHISPER", command = "WHISPER", requiresTarget = true },
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
    
    barFrame = CreateFrame("Frame", "ChatBarFrame", UIParent, "BackdropTemplate")
    barFrame:SetFrameStrata("DIALOG")
    barFrame:SetSize(100, 40) -- Will be resized based on buttons
    
    -- Set initial position (will be overridden by saved position if exists)
    local settings = self:GetSettings()
    if settings.barPosition then
        barFrame:SetPoint(settings.barPosition.point, UIParent, settings.barPosition.relativePoint, settings.barPosition.x, settings.barPosition.y)
    else
        -- Default: Above chat frame tabs (chat tabs are about 20px tall)
        barFrame:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 24)
    end
    
    -- Apply bar theme
    self:ApplyBarTheme()
    
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

-- Apply bar theme
function ChatBar:ApplyBarTheme()
    if not barFrame then return end
    
    local settings = self:GetSettings()
    local theme = ns.Themes.bars[settings.barTheme] or ns.Themes.bars.classic
    
    barFrame:SetBackdrop(theme.backdrop)
    barFrame:SetBackdropColor(theme.bgColor.r, theme.bgColor.g, theme.bgColor.b, theme.bgColor.a)
    barFrame:SetBackdropBorderColor(theme.borderColor.r, theme.borderColor.g, theme.borderColor.b, theme.borderColor.a)
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
    
    barFrame:SetScript("OnEvent", function(frame, event, ...)
        if ChatBar[event] then
            ChatBar[event](ChatBar, ...)
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
    
    local button = CreateFrame("Button", "ChatBarButton" .. index, barFrame, "BackdropTemplate")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Create programmatic textures for button states
    button.normalTexture = button:CreateTexture(nil, "BACKGROUND")
    button.normalTexture:SetAllPoints()
    
    button.pushedTexture = button:CreateTexture(nil, "BACKGROUND")
    button.pushedTexture:SetAllPoints()
    
    button.highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlightTexture:SetAllPoints()
    button.highlightTexture:SetBlendMode("ADD")
    
    -- Set the textures to the button
    button:SetNormalTexture(button.normalTexture)
    button:SetPushedTexture(button.pushedTexture)
    button:SetHighlightTexture(button.highlightTexture)
    
    -- Create font string with proper template
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text = text
    text:SetPoint("CENTER")
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(1, 1, 1, 1) -- Default to white
    text:SetShadowColor(0, 0, 0, 1) -- Black shadow for visibility
    text:SetShadowOffset(1, -1)
    
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
    local theme = ns.Themes.buttons[settings.buttonTheme] or ns.Themes.buttons.classic
    
    button.channelData = channelData
    button:SetSize(theme.size, theme.size)
    
    -- Apply font FIRST (before SetText)
    if theme.font then
        local fontObject = _G[theme.font]
        if fontObject then
            button.text:SetFontObject(fontObject)
        end
    end
    
    -- Apply custom font size if configured
    local fontSize = settings.fontSize or 12
    local fontPath, _, fontFlags = button.text:GetFont()
    if fontPath then
        button.text:SetFont(fontPath, fontSize, fontFlags)
    end
    
    -- Set text color and ensure visibility
    button.text:SetTextColor(1, 1, 1, 1)
    button.text:Show() -- Explicitly show the text
    
    -- Set text
    if channelData.isNumbered then
        button.text:SetText(tostring(channelData.id)) -- Channel number
        print("ChatBar DEBUG: Set numbered button text to:", channelData.id)
    else
        local info = ns.ChannelInfo[channelData.channelType]
        if info and info.labelKey then
            -- Get localized label
            local label = L[info.labelKey]
            
            -- Extract first character (UTF-8 aware)
            local firstChar = "?"
            if label and type(label) == "string" and #label > 0 then
                -- Use UTF-8 aware substring for multi-byte characters (Cyrillic, etc.)
                if string.utf8sub then
                    firstChar = string.utf8sub(label, 1, 1):upper()
                else
                    -- Fallback: extract first UTF-8 character using pattern
                    firstChar = (label:match("^([%z\1-\127\194-\244][\128-\191]*)") or "?"):upper()
                end
            end
            
            print("ChatBar DEBUG: Channel", channelData.channelType, "labelKey:", info.labelKey, "label:", label, "firstChar:", firstChar)
            button.text:SetText(firstChar)
            
            -- Debug: verify text was set
            local actualText = button.text:GetText()
            print("ChatBar DEBUG: After SetText, GetText returns:", actualText)
        else
            -- Fallback
            print("ChatBar DEBUG: No info found for channel:", channelData.channelType)
            button.text:SetText("?")
        end
    end
    
    -- Apply textures/colors AFTER setting text
    self:ApplyButtonTheme(button, theme, channelData)
    
    -- Set enabled state
    local available = channelData.isNumbered or self:IsChannelAvailable(channelData.channelType)
    button:SetEnabled(available)
    button:SetAlpha(available and 1.0 or 0.5)
end

-- Apply button theme
function ChatBar:ApplyButtonTheme(button, theme, channelData)
    -- Get chat color for this channel
    local chatType = channelData.isNumbered and "CHANNEL" or channelData.channelType
    local chatColor = ChatTypeInfo[chatType]
    
    if theme.useProgrammaticTextures then
        -- Use programmatic color textures
        if button.normalTexture then
            if theme.useChatColors and chatColor then
                -- Tint button with channel color
                button.normalTexture:SetColorTexture(
                    chatColor.r * 0.5 + theme.normalColor.r * 0.5,
                    chatColor.g * 0.5 + theme.normalColor.g * 0.5,
                    chatColor.b * 0.5 + theme.normalColor.b * 0.5,
                    theme.normalColor.a
                )
            else
                button.normalTexture:SetColorTexture(
                    theme.normalColor.r,
                    theme.normalColor.g,
                    theme.normalColor.b,
                    theme.normalColor.a
                )
            end
        end
        
        if button.pushedTexture then
            if theme.useChatColors and chatColor then
                button.pushedTexture:SetColorTexture(
                    chatColor.r * 0.4 + theme.pushedColor.r * 0.6,
                    chatColor.g * 0.4 + theme.pushedColor.g * 0.6,
                    chatColor.b * 0.4 + theme.pushedColor.b * 0.6,
                    theme.pushedColor.a
                )
            else
                button.pushedTexture:SetColorTexture(
                    theme.pushedColor.r,
                    theme.pushedColor.g,
                    theme.pushedColor.b,
                    theme.pushedColor.a
                )
            end
        end
        
        if button.highlightTexture then
            button.highlightTexture:SetColorTexture(
                theme.highlightColor.r,
                theme.highlightColor.g,
                theme.highlightColor.b,
                theme.highlightColor.a
            )
        end
        
        -- Apply border using backdrop
        if theme.borderSize and theme.borderSize > 0 then
            button:SetBackdrop({
                bgFile = nil,
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                edgeSize = theme.borderSize,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            
            if theme.useChatColors and chatColor then
                button:SetBackdropBorderColor(chatColor.r, chatColor.g, chatColor.b, theme.borderColor.a)
            else
                button:SetBackdropBorderColor(
                    theme.borderColor.r,
                    theme.borderColor.g,
                    theme.borderColor.b,
                    theme.borderColor.a
                )
            end
        else
            button:SetBackdrop(nil)
        end
    end
    
    -- Set text color
    if theme.useChatColors and chatColor then
        button.text:SetTextColor(chatColor.r, chatColor.g, chatColor.b, 1)
    else
        button.text:SetTextColor(1, 1, 1, 1)
    end
end

-- Layout buttons based on orientation
function ChatBar:LayoutButtons()
    if #activeButtons == 0 then return end
    
    local settings = self:GetSettings()
    local theme = ns.Themes.buttons[settings.buttonTheme] or ns.Themes.buttons.classic
    local barTheme = ns.Themes.bars[settings.barTheme] or ns.Themes.bars.classic
    
    local padding = barTheme.padding
    local spacing = theme.spacing
    local buttonSize = theme.size
    
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
    
    local channelData = button.channelData
    
    if channelData.isNumbered then
        -- Numbered channel - open chat first, then set channel
        ChatFrame_OpenChat("", currentChatFrame)
        local editBox = currentChatFrame.editBox
        if editBox then
            editBox:SetAttribute("chatType", "CHANNEL")
            editBox:SetAttribute("channelTarget", channelData.id)
            ChatEdit_UpdateHeader(editBox)
        end
    else
        -- Standard channel
        local info = ns.ChannelInfo[channelData.channelType]
        if info then
            if info.requiresTarget and channelData.channelType == "WHISPER" then
                -- For whisper, open chat with /w command
                ChatFrame_OpenChat("/w ", currentChatFrame)
                return
            else
                -- Open chat and set channel type
                ChatFrame_OpenChat("", currentChatFrame)
                local editBox = currentChatFrame.editBox
                if editBox then
                    editBox:SetAttribute("chatType", info.command)
                    ChatEdit_UpdateHeader(editBox)
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

-- Refresh the addon (reapply themes, rebuild buttons)
function ChatBar:Refresh()
    self:ApplyBarTheme()
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
        else
            ChatBarDB = self:CopyTable(ns.Defaults)
            ns.db = ChatBarDB
        end
        self:Refresh()
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
        else
            -- Merge with defaults for missing keys
            ChatBar:MergeDefaults(ns.db, ns.Defaults)
        end
        
        ns.charDB = ChatBarCharDB or {}
        if not ChatBarCharDB then
            ChatBarCharDB = ChatBar:CopyTable(ns.Defaults)
            ns.charDB = ChatBarCharDB
        else
            ChatBar:MergeDefaults(ns.charDB, ns.Defaults)
        end
        
        -- Now initialize UI
        ChatBar:Initialize()
        
        -- Initialize Config
        if ns.Config then
            ns.Config:Initialize()
        end
        
        -- Print loaded message with localized string
        print(string.format("%s v%s %s. %s", 
            L.ADDON_NAME,
            ChatBar.VERSION,
            L.ADDON_LOADED,
            L.ADDON_SLASH_HELP
        ))
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
