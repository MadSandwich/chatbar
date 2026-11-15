-- ChatBar: Simplified Chinese Localization
--
-- Terms follow the zhCN client's own GlobalStrings (SAY, YELL, RAID_WARNING,
-- KEY_BINDINGS, HUD_EDIT_MODE_MENU, ...), and labels end in the full-width
-- colon the client uses. "聊天条" is the bar, after 动作条; the client's
-- "聊天栏" means the chat window itself. Whisper is 密语 rather than WHISPER's
-- 悄悄话: the client uses 密语 for the whisper window and for Battle.net
-- whispers, which the one Whisper button also reaches.

local _, ns = ...
if GetLocale() ~= "zhCN" then
    return
end
local L = ns.L

L["ADDON_LOADED"] = "已加载"
L["ADDON_SLASH_HELP"] = "输入|cffff8800/chatbar|r打开设置。"

L["CHAT_SAY"] = "说"
L["CHAT_YELL"] = "大喊"
L["CHAT_EMOTE"] = "表情"
L["CHAT_WHISPER"] = "密语"
L["CHAT_PARTY"] = "小队"
L["CHAT_RAID"] = "团队"
L["CHAT_RAID_WARNING"] = "团队通知"
L["CHAT_INSTANCE"] = "副本"
L["CHAT_GUILD"] = "公会"
L["CHAT_OFFICER"] = "官员"
L["CHAT_REPLY"] = "回复"

L["SETTINGS_TITLE"] = "ChatBar 设置"
L["VERSION"] = "版本"
L["PROFILE_MODE"] = "配置模式："
L["PROFILE_ACCOUNT"] = "账号通用（所有角色共享）"
L["PROFILE_CHARACTER"] = "角色专用设置"
L["APPEARANCE"] = "外观"
L["THEME"] = "主题"
L["BUTTON_SHAPE"] = "按钮形状"
L["SHAPE_SQUARE"] = "方形"
L["SHAPE_CIRCLE"] = "圆形"
L["ACCENT"] = "强调色"
L["ACCENT_CLASS"] = "职业颜色"
L["ACCENT_TEAL"] = "青绿"
L["ACCENT_AZURE"] = "天蓝"
L["ACCENT_EMBER"] = "余烬"
L["ACCENT_VIOLET"] = "紫罗兰"
L["ACCENT_GOLD"] = "金色"
L["ACCENT_MONO"] = "白色"
L["ACCENT_CUSTOM"] = "自定义……"
L["FONT"] = "字体"
L["FONT_DEFAULT"] = "默认"
L["FONT_EXPRESSWAY"] = "Expressway"
L["BACKGROUND_COLOR"] = "背景"
L["BACKGROUND_COLOR_HINT"] = "右键点击可以使用主题自带的颜色。"
L["BACKGROUND_OPACITY"] = "聊天条不透明度"
L["BACKGROUND_OPACITY_HINT"] = "仅作用于聊天条背景，不影响频道按钮。"
L["BACKGROUND_OPACITY_NO_BAR"] = "当前主题不绘制聊天条背景。"
L["SKIN_AUTHOR"] = "作者"

-- Themes
L["THEME_FLAT"] = "扁平"
L["THEME_FLAT_DESC"] = "按频道着色的按钮底板，当前频道实心填充，聊天条下方有一条强调色线。"
L["THEME_GLASS"] = "玻璃"
L["THEME_GLASS_DESC"] = "同一设计的玻璃版：带光泽的渐变高光与强调色边框。"
L["ORIENTATION"] = "方位："
L["ORIENTATION_HORIZONTAL"] = "水平"
L["ORIENTATION_VERTICAL"] = "垂直"
L["ENABLED_CHANNELS"] = "启用的频道："
L["NUMBERED_CHANNELS"] = "编号频道："
L["SHOW_NUMBERED_CHANNELS"] = "显示编号频道（综合、交易等）"
L["NUMBERED_CHANNEL_FILTERS"] = "单独筛选频道："
L["NUMBERED_CHANNEL_NONE"] = "当前未加入任何编号频道。"
L["NUMBERED_CHANNEL_INACTIVE"] = "当前未激活（例如在主城外的交易频道）"
L["FLASH_NOTIFICATIONS"] = "闪烁提醒："
L["FLASH_NOTIFICATIONS_DESC"] = "收到新消息时按钮闪烁"
L["HIDE_LOADED_MESSAGE"] = "不在聊天框中显示加载消息"
L["FONT_SIZE"] = "字体大小："
L["BUTTON_SIZE"] = "按钮大小："
L["TEXT_POSITION"] = "文字位置："
L["TEXT_POSITION_INSIDE"] = "按钮内"
L["TEXT_POSITION_ABOVE"] = "按钮上方"
L["POSITION"] = "位置："
L["LOCK_POSITION"] = "锁定聊天条位置"
L["LOCK_POSITION_EDIT_MODE_HINT"] = "编辑模式仍可移动已锁定的聊天条。"

-- Override keybinding globals for Simplified Chinese
_G["BINDING_HEADER_CHATBAR"] = "ChatBar"
_G["BINDING_NAME_CHATBAR_TOGGLE"] = "显示/隐藏 ChatBar"
_G["BINDING_NAME_CHATBAR_SWITCH_SAY"] = "切换到说"
_G["BINDING_NAME_CHATBAR_SWITCH_YELL"] = "切换到大喊"
_G["BINDING_NAME_CHATBAR_SWITCH_EMOTE"] = "切换到表情"
_G["BINDING_NAME_CHATBAR_SWITCH_WHISPER"] = "切换到密语"
_G["BINDING_NAME_CHATBAR_QUICK_REPLY"] = "快速回复上一条密语"
_G["BINDING_NAME_CHATBAR_SWITCH_PARTY"] = "切换到小队"
_G["BINDING_NAME_CHATBAR_SWITCH_RAID"] = "切换到团队"
_G["BINDING_NAME_CHATBAR_SWITCH_GUILD"] = "切换到公会"
_G["BINDING_NAME_CHATBAR_SWITCH_OFFICER"] = "切换到官员"
_G["BINDING_NAME_CHATBAR_CYCLE_PREV"] = "切换到上一个频道"
_G["BINDING_NAME_CHATBAR_CYCLE_NEXT"] = "切换到下一个频道"
L["CHANNEL_HISTORY_DESC"] = "启用频道历史切换（在按键设置中分配按键）"
L["MSG_HISTORY_EMPTY"] = "尚无频道历史。请先切换频道。"
L["MSG_NO_WHISPER_TARGET"] = "暂无可回复的对象。请先发送或收到一条密语。"
L["MSG_CHANNEL_UNAVAILABLE"] = "%s当前不可用。"

L["MSG_BAR_SHOWN"] = "聊天条已显示"
L["MSG_BAR_HIDDEN"] = "聊天条已隐藏"
L["MSG_RESET"] = "正在恢复默认设置……"
L["MSG_RESET_COMPLETE"] = "设置已重置！"
L["MSG_STILL_LOADING"] = "插件仍在加载，请稍后再试。"
L["MSG_SETTINGS_LOADING"] = "设置面板仍在加载，请稍后再试。"

L["TOOLTIP_CHANNEL"] = "频道"
L["TOOLTIP_CHAT"] = "聊天"
L["TOOLTIP_CLICK_SWITCH"] = "点击切换频道"

L["CMD_HELP_HEADER"] = "命令："
L["CMD_OPEN_SETTINGS"] = "打开设置"
L["CMD_TOGGLE"] = "切换聊天条显示"
L["CMD_SHOW"] = "显示聊天条"
L["CMD_HIDE"] = "隐藏聊天条"
L["CMD_RESET"] = "恢复默认设置"
L["CMD_HELP"] = "显示此帮助"
