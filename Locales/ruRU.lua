-- ChatBar: Russian Localization

local addonName, ns = ...
if GetLocale() ~= "ruRU" then return end

local L = ns.L

L.ADDON_LOADED = "загружен"
L.ADDON_SLASH_HELP = "Введите |cffff8800/chatbar|r для настроек."

L.CHAT_SAY = "Сказать"
L.CHAT_YELL = "Крикнуть"
L.CHAT_EMOTE = "Эмоция"
L.CHAT_WHISPER = "Шепот"
L.CHAT_PARTY = "Группа"
L.CHAT_RAID = "Рейд"
L.CHAT_RAID_WARNING = "Объявление рейду"
L.CHAT_INSTANCE = "Подземелье"
L.CHAT_GUILD = "Гильдия"
L.CHAT_OFFICER = "Офицер"
L.CHAT_BATTLEGROUND = "Поле боя"

L.SETTINGS_TITLE = "Настройки ChatBar"
L.VERSION = "Версия"
L.PROFILE_MODE = "Режим профиля:"
L.PROFILE_ACCOUNT = "На весь аккаунт (общий для всех персонажей)"
L.PROFILE_CHARACTER = "Настройки для персонажа"
L.BUTTON_THEME = "Тема кнопок:"
L.BAR_THEME = "Тема панели:"
L.ORIENTATION = "Ориентация:"
L.ORIENTATION_HORIZONTAL = "Горизонтальная"
L.ORIENTATION_VERTICAL = "Вертикальная"
L.ENABLED_CHANNELS = "Включенные каналы:"
L.NUMBERED_CHANNELS = "Нумерованные каналы:"
L.SHOW_NUMBERED_CHANNELS = "Показывать нумерованные каналы (Общий, Торговля и т.д.)"

L.MSG_BAR_SHOWN = "Панель показана"
L.MSG_BAR_HIDDEN = "Панель скрыта"
L.MSG_BAR_TOGGLED = "Панель"
L.MSG_RESET = "Сброс к настройкам по умолчанию..."
L.MSG_RESET_COMPLETE = "Настройки сброшены!"
L.MSG_STILL_LOADING = "Аддон все еще загружается, попробуйте еще раз через мгновение."
L.MSG_SETTINGS_LOADING = "Панель настроек все еще загружается, попробуйте еще раз через мгновение."

L.TOOLTIP_CHANNEL = "Канал"
L.TOOLTIP_CHAT = "Чат"
L.TOOLTIP_CLICK_SWITCH = "Нажмите для переключения канала"

L.CMD_HELP_HEADER = "Команды:"
L.CMD_OPEN_SETTINGS = "Открыть настройки"
L.CMD_TOGGLE = "Переключить видимость панели"
L.CMD_SHOW = "Показать панель"
L.CMD_HIDE = "Скрыть панель"
L.CMD_RESET = "Сбросить к настройкам по умолчанию"
L.CMD_HELP = "Показать эту справку"
