-- ChatBar: Spanish Localization

local addonName, ns = ...
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

local L = ns.L

L.ADDON_LOADED = "cargado"
L.ADDON_SLASH_HELP = "Escribe |cffff8800/chatbar|r para opciones."

L.CHAT_SAY = "Decir"
L.CHAT_YELL = "Gritar"
L.CHAT_EMOTE = "Emote"
L.CHAT_WHISPER = "Susurrar"
L.CHAT_PARTY = "Grupo"
L.CHAT_RAID = "Banda"
L.CHAT_RAID_WARNING = "Aviso de Banda"
L.CHAT_INSTANCE = "Instancia"
L.CHAT_GUILD = "Hermandad"
L.CHAT_OFFICER = "Oficial"
L.CHAT_BATTLEGROUND = "Campo de Batalla"

L.SETTINGS_TITLE = "Configuración de ChatBar"
L.VERSION = "Versión"
L.PROFILE_MODE = "Modo de Perfil:"
L.PROFILE_ACCOUNT = "Cuenta completa (compartido entre personajes)"
L.PROFILE_CHARACTER = "Configuración por personaje"
L.BUTTON_THEME = "Tema de Botones:"
L.BAR_THEME = "Tema de Barra:"
L.ORIENTATION = "Orientación:"
L.ORIENTATION_HORIZONTAL = "Horizontal"
L.ORIENTATION_VERTICAL = "Vertical"
L.ENABLED_CHANNELS = "Canales Habilitados:"
L.NUMBERED_CHANNELS = "Canales Numerados:"
L.SHOW_NUMBERED_CHANNELS = "Mostrar canales numerados (General, Comercio, etc.)"

L.MSG_BAR_SHOWN = "Barra mostrada"
L.MSG_BAR_HIDDEN = "Barra oculta"
L.MSG_BAR_TOGGLED = "Barra"
L.MSG_RESET = "Restableciendo valores predeterminados..."
L.MSG_RESET_COMPLETE = "¡Configuración restablecida!"
L.MSG_STILL_LOADING = "El addon aún se está cargando, inténtalo de nuevo en un momento."
L.MSG_SETTINGS_LOADING = "El panel de configuración aún se está cargando, inténtalo de nuevo en un momento."

L.TOOLTIP_CHANNEL = "Canal"
L.TOOLTIP_CHAT = "Chat"
L.TOOLTIP_CLICK_SWITCH = "Haz clic para cambiar de canal"

L.CMD_HELP_HEADER = "Comandos:"
L.CMD_OPEN_SETTINGS = "Abrir configuración"
L.CMD_TOGGLE = "Alternar visibilidad de barra"
L.CMD_SHOW = "Mostrar barra"
L.CMD_HIDE = "Ocultar barra"
L.CMD_RESET = "Restablecer valores predeterminados"
L.CMD_HELP = "Mostrar esta ayuda"
