-- ChatBar: Quick chat channel switcher addon
-- Main addon file

local addonName, ns = ...

-- Create addon object
local ChatBar = {}
ns.ChatBar = ChatBar

-- Version constant
ChatBar.VERSION = "3.0.0"

-- Maximum number of recently-used channels remembered for history cycling
ChatBar.MAX_HISTORY = 10

-- Default settings
ns.Defaults = {
    version = 3,
    profileMode = "account", -- "account" or "character"
    theme = "Flat", -- Design theme id, see Themes/
    buttonShape = "square", -- "square" or "circle"; a theme may fix its own and ignore this
    accent = "class", -- Accent source: "class", a preset name, or "custom"
    accentColor = nil, -- {r, g, b} used when accent == "custom"
    font = "default", -- Label font, see ns.Theme.FONT_CHOICES
    backgroundColor = nil, -- {r, g, b} overriding the theme's surface colour
    backgroundOpacity = 1, -- Multiplies the theme's surface alpha, 0 to 1
    activeChannel = nil, -- Remembered channel selection {isNumbered, channelType, id, name}
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
    
    -- Channel history cycling (session-only history; toggle enables recording)
    channelHistory = {
        enabled = true, -- Track recently used channels for keybind cycling
    },

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

        -- Quick-reply to the most recent whisper sender (auto-resolved target)
        REPLY = { enabled = false, order = 13 },
    },
    
    -- Numbered channels (General, Trade, LocalDefense, etc.)
    numberedChannels = {
        enabled = true,
        filters = {}, -- Kept for saved-variable backward compatibility; no longer used
        excluded = {} -- Blacklist: excluded[channelName] = true hides that channel
    }
}

-- Theme registry (populated by the files in Themes/)
ns.ThemeRegistry = ns.ThemeRegistry or {}

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
    REPLY = { labelKey = "CHAT_REPLY", command = "REPLY", requiresTarget = true },
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

-- Blizzard's chat helpers moved onto the ChatFrameUtil namespace; the bare
-- ChatEdit_* globals remain as compatibility shims. Prefer the namespace and
-- fall back, the same way OpenChatWithFallback above does.
local function ChooseBoxForSend()
    if ChatFrameUtil and ChatFrameUtil.ChooseBoxForSend then
        return ChatFrameUtil.ChooseBoxForSend()
    end
    if ChatEdit_ChooseBoxForSend then
        return ChatEdit_ChooseBoxForSend()
    end
    return nil
end

local function SetLastActiveWindow(editBox)
    if not editBox then return end
    if ChatFrameUtil and ChatFrameUtil.SetLastActiveWindow then
        ChatFrameUtil.SetLastActiveWindow(editBox)
    elseif ChatEdit_SetLastActiveWindow then
        ChatEdit_SetLastActiveWindow(editBox)
    end
end

local function ActivateChat(editBox)
    if not editBox then return end
    if ChatFrameUtil and ChatFrameUtil.ActivateChat then
        ChatFrameUtil.ActivateChat(editBox)
    elseif ChatEdit_ActivateChat then
        ChatEdit_ActivateChat(editBox)
    end
end

-- Resolve the current numbered-channel id for a channel name.
-- Channel ids can change between zones/sessions, so cycling looks them up by name.
local function GetNumberedChannelIdByName(name)
    if not name then return nil end
    local channelList = { GetChannelList() }
    for i = 1, #channelList, 3 do
        if channelList[i + 1] == name then
            return channelList[i]
        end
    end
    return nil
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
    -- Session-only channel history for cycling (intentionally not persisted)
    self.channelHistory = {}
    self.cycleIndex = 1

    -- The remembered channel selection, unlike the history, does persist.
    self.activeChannel = self:GetSettings().activeChannel

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

-- The texture-file skins the design engine replaced, mapped onto the theme and
-- shape that reproduce them most closely.
local SKIN_MIGRATION = {
    Default = { theme = "Flat",  buttonShape = "square" },
    Round   = { theme = "Glass", buttonShape = "circle" },
    -- The old Minimal skin was letters on a bare plate. Flat is what that
    -- became: the plate is still nearly invisible at rest, and the accent
    -- underline it was built around is now part of the theme.
    Minimal = { theme = "Flat",  buttonShape = "square" },
}

-- Shapes a *profile* may name. "rounded" is absent on purpose: it is a theme's
-- own outline rather than a player choice, so a stored "rounded" is stale and
-- gets cleared back to whatever the active theme draws.
local VALID_SHAPES = { square = true, circle = true }

-- Repair appearance settings that no longer name anything real.
--
-- Runs on every load rather than only on a version bump: a theme can be renamed
-- or dropped between releases, and a profile still pointing at it would leave
-- the settings dropdown displaying a value the engine silently ignores. Repairs
-- are written back into the profile so what is saved matches what is drawn.
function ChatBar:ValidateProfile(profile)
    if not (profile.theme and ns.ThemeRegistry[profile.theme]) then
        profile.theme = ns.Defaults.theme
    end

    if not VALID_SHAPES[profile.buttonShape] then
        profile.buttonShape = ns.Defaults.buttonShape
    end

    if profile.accent and ns.Theme and not ns.Theme:IsAccentAvailable(profile.accent) then
        profile.accent = ns.Defaults.accent
    end

    -- A custom accent with no stored colour would resolve to the fallback on
    -- every read while still claiming to be custom in the UI.
    if profile.accent == "custom" and type(profile.accentColor) ~= "table" then
        profile.accent = ns.Defaults.accent
    end

    -- Also catches ids retired between releases, which would otherwise leave the
    -- dropdown blank over a face the engine had already fallen back from.
    if profile.font and ns.Theme and not ns.Theme:IsFontAvailable(profile.font) then
        profile.font = ns.Defaults.font
    end

    local opacity = tonumber(profile.backgroundOpacity)
    if not opacity then
        profile.backgroundOpacity = ns.Defaults.backgroundOpacity
    else
        -- A stored 0 would render every surface invisible with no obvious cause,
        -- so the floor keeps the bar findable.
        profile.backgroundOpacity = math.max(0.05, math.min(1, opacity))
    end

    if profile.backgroundColor ~= nil and type(profile.backgroundColor) ~= "table" then
        profile.backgroundColor = nil
    end
end

-- Bring a saved profile up to the current settings schema. Runs before defaults
-- are merged in, so a migrated value is not shadowed by a fresh default.
function ChatBar:MigrateProfile(profile)
    if type(profile) ~= "table" then return end

    local version = profile.version or 1

    -- v3: skins became themes. Carry the player's chosen look across rather
    -- than silently resetting everyone to the default.
    if version < 3 then
        if profile.skinName and not profile.theme then
            local mapped = SKIN_MIGRATION[profile.skinName]
            if mapped then
                profile.theme = mapped.theme
                profile.buttonShape = mapped.buttonShape
            end
        end
        profile.skinName = nil
    end

    profile.version = ns.Defaults.version

    self:ValidateProfile(profile)
end

-- Apply a theme's default font size, used on first install and when the player
-- picks a theme whose text scale differs from the one they were on.
function ChatBar:ApplyThemeFontDefault(profile)
    local theme = ns.Theme and ns.Theme:Get(profile.theme or ns.Defaults.theme)
    if theme and theme.layout and theme.layout.defaultFontSize then
        profile.fontSize = theme.layout.defaultFontSize
    end
end

-- Create main bar frame
function ChatBar:CreateBarFrame()
    if barFrame then return end
    
    -- Load the player's theme
    local settings = self:GetSettings()
    ns.Design:LoadTheme(settings.theme)

    barFrame = CreateFrame("Frame", "ChatBarFrame", UIParent)
    barFrame:SetFrameStrata("MEDIUM")
    barFrame:SetSize(100, 40) -- Will be resized based on buttons

    -- Build the bar's themed surfaces
    ns.Design:BuildBar(barFrame)
    
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
            -- Save position, snapped to the pixel grid so the bar lands in the
            -- same place after a reload instead of drifting a pixel at a time.
            local point, _, relativePoint, x, y = self:GetPoint()
            settings.barPosition = {
                point = point,
                relativePoint = relativePoint,
                x = ns.Pixel.Snap(x),
                y = ns.Pixel.Snap(y)
            }
            self:ClearAllPoints()
            self:SetPoint(point, UIParent, relativePoint, settings.barPosition.x, settings.barPosition.y)
        end
    end)
    
    barFrame:Show()
end

-- Repaint the bar from the current theme
function ChatBar:RefreshBarTextures()
    if not barFrame then return end
    ns.Design:StyleBar(barFrame)
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

    -- PositionBar pins the bar to UIParent on the pixel grid rather than
    -- live-anchoring it to the chat frame, so it needs a nudge whenever the
    -- player moves or resizes a chat window.
    --
    -- Deferred by a frame on purpose: this hook fires inside Blizzard's dock
    -- bookkeeping, and running insecure layout work synchronously in that chain
    -- can taint the dock state the secure whisper-window path later reads.
    if not self.chatPositionHooked and FCF_SavePositionAndDimensions then
        self.chatPositionHooked = true
        hooksecurefunc("FCF_SavePositionAndDimensions", function()
            C_Timer.After(0, function()
                ChatBar:PositionBar()
            end)
        end)
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

    -- The chat frame sits wherever the player dragged it, which is rarely a
    -- whole pixel. Anchoring straight to it hands that fractional origin to
    -- every button and label in the bar, and small text rendered off-grid goes
    -- soft. Re-anchor to UIParent on the grid instead, keeping the same spot.
    ns.Pixel.SnapFrame(barFrame)
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
    
    -- Start the themed alert pulse
    ns.Design:StartAlert(button)
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
    
    -- Stop the themed alert pulse
    ns.Design:StopAlert(button)
    
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
    
    if channelType == "REPLY" then
        return true -- Always available; target auto-resolved from last whisper
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
    local excluded = settings.numberedChannels.excluded or {}
    
    for i = 1, #channelList, 3 do
        local id   = channelList[i]
        local name = channelList[i + 1]
        
        if id and name and not excluded[name] then
            table.insert(channels, {
                id = id,
                name = name,
                channelType = "CHANNEL",
                order = 100 + id,
                isNumbered = true
            })
        end
    end
    
    return channels
end

-- Update buttons based on available channels
function ChatBar:UpdateButtons()
    if not barFrame then return end
    
    local settings = self:GetSettings()
    
    -- Hide all existing buttons. Stopping the alert first matters: a pooled
    -- button that goes out of service mid-pulse would otherwise keep its ticker
    -- running and carry the old channel's alert state into its next channel.
    for _, button in pairs(activeButtons) do
        self:StopFlashButton(button)
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

    -- Flash state tracking; the pulse itself belongs to the design engine
    button.isFlashing = false
    button.flashStopTime = nil

    -- Scripts are set before Design builds the button, so the engine's own
    -- hover and press hooks compose on top of these rather than replacing them.
    button:SetScript("OnClick", function(self, mouseButton)
        ChatBar:OnButtonClick(self, mouseButton)
    end)

    button:SetScript("OnEnter", function(self)
        ChatBar:OnButtonEnter(self)
    end)

    button:SetScript("OnLeave", function(self)
        ChatBar:OnButtonLeave(self)
    end)

    -- Builds the texture stack and the label (exposed as button.text)
    ns.Design:BuildButton(button)

    buttonPool[index] = button
    return button
end

-- The glyph shown on a button: the channel number, or the first character of
-- the localized channel name.
function ChatBar:GetButtonGlyph(channelData)
    local L = ns.L

    if channelData.isNumbered then
        return tostring(channelData.id)
    end

    local info = ns.ChannelInfo[channelData.channelType]
    if not (info and info.labelKey) then return "?" end

    local label = L[info.labelKey]
    if type(label) ~= "string" or #label == 0 then return "?" end

    -- Match one whole UTF-8 sequence, not one byte: Cyrillic and Korean names
    -- would otherwise be sliced mid-character.
    return (label:match("^([%z\1-\127\194-\244][\128-\191]*)") or "?"):upper()
end

-- The colour a channel should carry.
--
-- Numbered channels are resolved per-slot ("CHANNEL1", "CHANNEL2", ...) rather
-- than through the generic "CHANNEL" entry, so anything that wants to colour
-- them the way the chat window does still can. The design engine deliberately
-- does not: it is passed `numbered` alongside this colour and drops it, because
-- a row of digits reads better as one neutral group than as four arbitrary
-- hues competing with the named channels around them.
-- Slots past the ones Blizzard defines fall back to the generic colour.
function ChatBar:GetChannelColor(channelData)
    if channelData.isNumbered then
        return ChatTypeInfo["CHANNEL" .. tostring(channelData.id)] or ChatTypeInfo.CHANNEL
    end
    return ChatTypeInfo[channelData.channelType]
end

-- True when this is the channel the edit box is currently pointed at.
function ChatBar:IsActiveChannel(channelData)
    return self.activeChannel ~= nil and self:IsSameChannel(self.activeChannel, channelData)
end

-- Setup button for a channel
function ChatBar:SetupButton(button, channelData)
    local settings = self:GetSettings()

    button.channelData = channelData

    local chatColor = self:GetChannelColor(channelData)
    local available = channelData.isNumbered or self:IsChannelAvailable(channelData.channelType)

    button.text:SetText(self:GetButtonGlyph(channelData))

    ns.Design:StyleButton(button, {
        size = settings.buttonSize or 24,
        channelColor = chatColor,
        numbered = channelData.isNumbered,
        fontSize = settings.fontSize or ns.Design:GetDefaultFontSize(),
        textPosition = settings.textPosition,
        orientation = settings.orientation,
        enabled = available,
        active = self:IsActiveChannel(channelData),
    })

    button:SetEnabled(available)
end

-- Layout buttons based on orientation
function ChatBar:LayoutButtons()
    if #activeButtons == 0 then return end
    
    local Pixel = ns.Pixel
    local settings = self:GetSettings()

    local padding = ns.Design:GetPadding()
    local spacing = ns.Design:GetSpacing()
    local buttonSize = settings.buttonSize or 24
    local count = #activeButtons

    if settings.orientation == "horizontal" then
        local totalWidth = (buttonSize * count) + (spacing * (count - 1)) + (padding * 2)
        local totalHeight = buttonSize + (padding * 2)

        Pixel.Size(barFrame, totalWidth, totalHeight)

        for i, button in ipairs(activeButtons) do
            button:ClearAllPoints()
            local xOffset = padding + ((i - 1) * (buttonSize + spacing))
            Pixel.Point(button, "TOPLEFT", barFrame, "TOPLEFT", xOffset, -padding)
        end
    else
        local totalWidth = buttonSize + (padding * 2)
        local totalHeight = (buttonSize * count) + (spacing * (count - 1)) + (padding * 2)

        Pixel.Size(barFrame, totalWidth, totalHeight)

        for i, button in ipairs(activeButtons) do
            button:ClearAllPoints()
            local yOffset = -padding - ((i - 1) * (buttonSize + spacing))
            Pixel.Point(button, "TOP", barFrame, "TOP", 0, yOffset)
        end
    end
end

-- Quick-reply to the most recently whispered player (received or sent), using
-- Blizzard's own last-tell tracking (ChatFrameUtil.GetLastTellTarget/ReplyTell,
-- exposed globally by Blizzard_ChatFrameBase and always addon-accessible).
-- ChatBar never needs to track whisper senders itself: the default UI already
-- records the last tell target whenever CHAT_MSG_WHISPER/CHAT_MSG_BN_WHISPER
-- (or their _INFORM variants) fire. Works for both regular and Battle.net
-- whispers automatically (ReplyTell restores whichever type was last used).
-- Never recorded in channel history since there's no persistent "channel" here.
function ChatBar:QuickReplyLastWhisper(chatFrame, preservedText)
    local L = ns.L
    chatFrame = chatFrame or currentChatFrame or ChatFrame1
    if not chatFrame then return false end

    local hasLastTell
    if ChatFrameUtil and ChatFrameUtil.GetLastTellTarget then
        hasLastTell = ChatFrameUtil.GetLastTellTarget() ~= nil
    elseif ChatEdit_GetLastTellTarget then
        hasLastTell = ChatEdit_GetLastTellTarget() ~= nil
    end

    if not hasLastTell then
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_NO_WHISPER_TARGET))
        return false
    end

    if ChatFrameUtil and ChatFrameUtil.ReplyTell then
        ChatFrameUtil.ReplyTell(chatFrame)
    elseif ChatFrame_ReplyTell then
        ChatFrame_ReplyTell(chatFrame)
    else
        return false
    end

    local editBox = chatFrame.editBox
    if editBox then
        if not editBox:IsShown() then
            ActivateChat(editBox)
        end
        if preservedText and preservedText ~= "" then
            editBox:SetText(preservedText)
            editBox:SetCursorPosition(#preservedText)
        end
    end

    return true
end

-- Switch the active chat edit box to a channel descriptor.
-- channelData fields: isNumbered, channelType, id (numbered), name (numbered)
-- opts.preserveText: keep any in-progress message text
-- opts.record: record this switch into the cycling history
-- Returns true if a channel switch was performed.
function ChatBar:ActivateChannel(channelData, opts)
    if not channelData then return false end
    opts = opts or {}

    local chatFrame = currentChatFrame or ChatFrame1
    if not chatFrame then return false end

    -- Preserve current message text if requested and chat is open
    local preservedText = ""
    if opts.preserveText then
        local editBox = chatFrame.editBox
        if editBox and editBox:IsShown() then
            local text = editBox:GetText()
            -- Secret Values (12.0): a whisper edit box can hand back a protected
            -- string. Both `#text` and concatenating it error on one, so the
            -- guard has to come before any other use of the value.
            if issecretvalue and issecretvalue(text) then
                text = nil
            end
            if type(text) == "string" then
                preservedText = text
            end
        end
    end

    local switched = false

    if channelData.isNumbered then
        -- Numbered channel - resolve the current id by name (ids can change)
        local targetId = channelData.id
        if channelData.name then
            targetId = GetNumberedChannelIdByName(channelData.name) or targetId
        end

        local editBox = OpenChatWithFallback(preservedText, chatFrame)
        if editBox then
            if editBox.SetChatType then
                editBox:SetChatType("CHANNEL")
            elseif editBox.SetAttribute then
                editBox:SetAttribute("chatType", "CHANNEL")
            end

            if editBox.SetChannelTarget then
                editBox:SetChannelTarget(targetId)
            elseif editBox.SetAttribute then
                editBox:SetAttribute("channelTarget", targetId)
            end

            RefreshEditBoxHeader(editBox)
            -- Restore cursor position to end of preserved text
            if preservedText ~= "" then
                editBox:SetCursorPosition(#preservedText)
            end
            switched = true
        end
    else
        -- Standard channel
        local info = ns.ChannelInfo[channelData.channelType]
        if info then
            if channelData.channelType == "REPLY" then
                -- Quick-reply: target is auto-resolved from the last whisper; never recorded.
                return self:QuickReplyLastWhisper(chatFrame, preservedText)
            elseif info.requiresTarget and (channelData.channelType == "WHISPER" or channelData.channelType == "BN_WHISPER") then
                -- For whisper, open chat with /w command (needs a target; never recorded)
                local cmd = channelData.channelType == "BN_WHISPER" and "/bw " or "/w "
                -- Append preserved text after the command
                OpenChatWithFallback(cmd .. preservedText, chatFrame)
                return true
            else
                -- Open chat and set channel type using proper API
                local editBox = OpenChatWithFallback(preservedText, chatFrame)
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
                    switched = true
                end
            end
        end
    end

    if switched then
        self:SetActiveChannel(channelData)

        if opts.record then
            self:RecordChannelHistory(channelData)
        end
    end

    return switched
end

-- Remember which channel is selected and light up its button.
--
-- The selection is saved rather than tied to edit box focus: the player picked
-- a channel, and that choice outlives the moment the input box happens to be
-- open. It survives a reload for the same reason.
function ChatBar:SetActiveChannel(channelData)
    self.activeChannel = channelData

    local settings = self:GetSettings()
    if channelData then
        -- Store a plain descriptor, not the live table: the entries carry a
        -- transient `order` field, and numbered channel ids change between
        -- zones, so the name is what makes the record durable.
        settings.activeChannel = {
            isNumbered = channelData.isNumbered or false,
            channelType = channelData.channelType,
            id = channelData.id,
            name = channelData.name,
        }
    else
        settings.activeChannel = nil
    end

    self:UpdateActiveButton()
end

-- Button click handler
function ChatBar:OnButtonClick(button, mouseButton)
    if not currentChatFrame then return end

    -- Stop flashing when clicked
    self:StopFlashButton(button)

    self:ActivateChannel(button.channelData, { preserveText = true, record = true })
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

-- Repaint every visible button under the current theme (theme or accent swap)
function ChatBar:RefreshAllButtons()
    for _, button in pairs(activeButtons) do
        if button.channelData then
            self:SetupButton(button, button.channelData)
        end
    end
end

-- Mark exactly one button as the active channel and clear the rest.
function ChatBar:UpdateActiveButton()
    for _, button in pairs(activeButtons) do
        ns.Design:SetActive(button, button.channelData and self:IsActiveChannel(button.channelData))
    end
end

-- Refresh the addon (reload the theme, rebuild buttons)
function ChatBar:Refresh()
    local settings = self:GetSettings()

    -- A profile switch can change the theme out from under us, so reload it
    -- before anything repaints.
    ns.Design:LoadTheme(settings.theme)

    -- The shape may have changed with the theme; drop cached masks so the next
    -- style pass rebuilds them rather than reusing a square mask on a circle.
    for _, button in pairs(buttonPool) do
        ns.Design:ReleaseButton(button)
    end

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
            self:ApplyThemeFontDefault(ns.charDB)
        else
            ChatBarDB = self:CopyTable(ns.Defaults)
            ns.db = ChatBarDB
            self:ApplyThemeFontDefault(ns.db)
        end
        -- The remembered selection lives in the profile that was just replaced;
        -- drop the in-memory copy too or the accent stays on a stale channel.
        self.activeChannel = nil
        ns.Theme:Invalidate()
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
    local editBox = ChooseBoxForSend()
    if editBox then
        SetLastActiveWindow(editBox)
        RefreshEditBoxHeader(editBox)
        
        local chatType = info.command
        if editBox.SetChatType then
            editBox:SetChatType(chatType)
        elseif editBox.SetAttribute then
            editBox:SetAttribute("chatType", chatType)
        end

        RefreshEditBoxHeader(editBox)
        
        if not editBox:IsShown() then
            ActivateChat(editBox)
        end

        -- Record this switch so it can be reached via history cycling
        self:RecordChannelHistory({ isNumbered = false, channelType = channelType })
    end
end

-- Determine whether two channel history descriptors refer to the same channel.
function ChatBar:IsSameChannel(a, b)
    if not a or not b then return false end
    if (a.isNumbered or false) ~= (b.isNumbered or false) then return false end
    if a.isNumbered then
        if a.name and b.name then
            return a.name == b.name
        end
        return a.id == b.id
    end
    return a.channelType == b.channelType
end

-- Check whether a history entry's channel is currently available to switch to.
function ChatBar:IsHistoryEntryAvailable(entry)
    if not entry then return false end
    if entry.isNumbered then
        return GetNumberedChannelIdByName(entry.name) ~= nil
    end
    return self:IsChannelAvailable(entry.channelType)
end

-- Record a channel switch at the front of the most-recently-used history list.
function ChatBar:RecordChannelHistory(channelData)
    if not channelData then return end
    if not self.channelHistory then self.channelHistory = {} end

    local settings = self:GetSettings()
    if settings.channelHistory and settings.channelHistory.enabled == false then
        return
    end

    -- Channels that require a target (whispers) cannot be cycled to meaningfully.
    if not channelData.isNumbered then
        local info = ns.ChannelInfo[channelData.channelType]
        if info and info.requiresTarget then
            return
        end
    end

    -- Store a normalized copy so later button-pool reuse cannot mutate history.
    local entry = {
        isNumbered = channelData.isNumbered or false,
        channelType = channelData.channelType,
        id = channelData.id,
        name = channelData.name,
    }

    -- Move-to-front: drop any existing matching entry first.
    for i = #self.channelHistory, 1, -1 do
        if self:IsSameChannel(self.channelHistory[i], entry) then
            table.remove(self.channelHistory, i)
        end
    end

    table.insert(self.channelHistory, 1, entry)

    -- Cap history length.
    local maxSize = ChatBar.MAX_HISTORY or 10
    while #self.channelHistory > maxSize do
        table.remove(self.channelHistory)
    end

    -- A fresh switch resets the cycle cursor to the most-recent channel.
    self.cycleIndex = 1
end

-- Cycle through recently-used channels.
-- direction: 1 = older (previous), -1 = newer (next). Wraps around the list.
function ChatBar:CycleChannel(direction)
    local L = ns.L
    local settings = self:GetSettings()
    if settings.channelHistory and settings.channelHistory.enabled == false then
        return
    end

    direction = direction or 1
    local history = self.channelHistory or {}
    local n = #history
    if n == 0 then
        print(string.format("%s: %s", L.ADDON_NAME, L.MSG_HISTORY_EMPTY))
        return
    end

    -- Walk the list (wrapping) until an available channel is found.
    local index = self.cycleIndex or 1
    for _ = 1, n do
        index = ((index - 1 + direction) % n) + 1
        local entry = history[index]
        if entry and self:IsHistoryEntryAvailable(entry) then
            self.cycleIndex = index
            self:ActivateChannel(entry, { preserveText = true, record = false })
            return
        end
    end

    -- No currently-available channel found in history.
    print(string.format("%s: %s", L.ADDON_NAME, L.MSG_HISTORY_EMPTY))
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
            ChatBar:ApplyThemeFontDefault(ns.db)
        else
            -- Migrate first: defaults must not shadow a carried-over value.
            ChatBar:MigrateProfile(ns.db)
            ChatBar:MergeDefaults(ns.db, ns.Defaults)
        end

        ns.charDB = ChatBarCharDB or {}
        if not ChatBarCharDB then
            ChatBarCharDB = ChatBar:CopyTable(ns.Defaults)
            ns.charDB = ChatBarCharDB
            ChatBar:ApplyThemeFontDefault(ns.charDB)
        else
            ChatBar:MigrateProfile(ns.charDB)
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

function ChatBar_QuickReplyLastWhisper()
    if ns and ns.ChatBar then
        ns.ChatBar:ActivateChannel({ isNumbered = false, channelType = "REPLY" }, { preserveText = true })
    end
end

function ChatBar_CycleChannel(direction)
    if ns and ns.ChatBar then
        ns.ChatBar:CycleChannel(direction)
    end
end
