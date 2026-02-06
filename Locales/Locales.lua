-- ChatBar: Localization System
-- Default locale: enUS

local addonName, ns = ...

local L = setmetatable({}, {
    __index = function(t, k)
        return k -- Return the key itself if no translation exists
    end
})
ns.L = L

-- Addon Info
L.ADDON_NAME = "|cff00ff00ChatBar|r"
L.ADDON_LOADED = "loaded"
L.ADDON_SLASH_HELP = "Type |cffff8800/chatbar|r for options."

-- Chat Channels
L.CHAT_SAY = "Say"
L.CHAT_YELL = "Yell"
L.CHAT_EMOTE = "Emote"
L.CHAT_WHISPER = "Whisper"
L.CHAT_BN_WHISPER = "BNet"
L.CHAT_PARTY = "Party"
L.CHAT_RAID = "Raid"
L.CHAT_RAID_WARNING = "Raid Warning"
L.CHAT_INSTANCE = "Instance"
L.CHAT_GUILD = "Guild"
L.CHAT_OFFICER = "Officer"
L.CHAT_BATTLEGROUND = "Battleground"

-- Settings UI
L.SETTINGS_TITLE = "ChatBar Settings"
L.VERSION = "Version"
L.PROFILE_MODE = "Profile Mode:"
L.PROFILE_ACCOUNT = "Account-wide (shared across all characters)"
L.PROFILE_CHARACTER = "Per-character settings"
L.SKIN_SELECTION = "Skin:"
L.SKIN_AUTHOR = "by"
L.ORIENTATION = "Orientation:"
L.ORIENTATION_HORIZONTAL = "Horizontal"
L.ORIENTATION_VERTICAL = "Vertical"
L.ENABLED_CHANNELS = "Enabled Channels:"
L.NUMBERED_CHANNELS = "Numbered Channels:"
L.SHOW_NUMBERED_CHANNELS = "Show numbered channels (General, Trade, LocalDefense, etc.)"
L.FLASH_NOTIFICATIONS = "Flash Notifications:"
L.FLASH_NOTIFICATIONS_DESC = "Flash buttons when new messages arrive"
L.FONT_SIZE = "Font Size:"
L.BUTTON_SIZE = "Button Size:"
L.TEXT_POSITION = "Text Position:"
L.TEXT_POSITION_INSIDE = "Inside buttons"
L.TEXT_POSITION_ABOVE = "Above buttons"

-- Set globals for keybinding system (must be in global namespace)
_G["BINDING_HEADER_CHATBAR"] = "ChatBar"
_G["BINDING_NAME_CHATBAR_TOGGLE"] = "Toggle ChatBar"
_G["BINDING_NAME_CHATBAR_SWITCH_SAY"] = "Switch to Say"
_G["BINDING_NAME_CHATBAR_SWITCH_YELL"] = "Switch to Yell"
_G["BINDING_NAME_CHATBAR_SWITCH_EMOTE"] = "Switch to Emote"
_G["BINDING_NAME_CHATBAR_SWITCH_WHISPER"] = "Switch to Whisper"
_G["BINDING_NAME_CHATBAR_SWITCH_BN_WHISPER"] = "Switch to Battle.net Whisper"
_G["BINDING_NAME_CHATBAR_SWITCH_PARTY"] = "Switch to Party"
_G["BINDING_NAME_CHATBAR_SWITCH_RAID"] = "Switch to Raid"
_G["BINDING_NAME_CHATBAR_SWITCH_GUILD"] = "Switch to Guild"
_G["BINDING_NAME_CHATBAR_SWITCH_OFFICER"] = "Switch to Officer"
_G["BINDING_NAME_CHATBAR_SWITCH_BATTLEGROUND"] = "Switch to Battleground"

-- Messages
L.MSG_BAR_SHOWN = "Bar shown"
L.MSG_BAR_HIDDEN = "Bar hidden"
L.MSG_BAR_TOGGLED = "Bar"
L.MSG_RESET = "Resetting to defaults..."
L.MSG_RESET_COMPLETE = "Settings reset!"
L.MSG_STILL_LOADING = "Addon is still loading, please try again in a moment."
L.MSG_SETTINGS_LOADING = "Settings panel is still loading, please try again in a moment."

-- Tooltips
L.TOOLTIP_CHANNEL = "Channel"
L.TOOLTIP_CHAT = "Chat"
L.TOOLTIP_CLICK_SWITCH = "Click to switch channel"

-- Commands
L.CMD_HELP_HEADER = "Commands:"
L.CMD_OPEN_SETTINGS = "Open settings"
L.CMD_TOGGLE = "Toggle bar visibility"
L.CMD_SHOW = "Show bar"
L.CMD_HIDE = "Hide bar"
L.CMD_RESET = "Reset to defaults"
L.CMD_HELP = "Show this help"
