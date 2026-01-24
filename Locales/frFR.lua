-- ChatBar: French Localization

local addonName, ns = ...
if GetLocale() ~= "frFR" then return end

local L = ns.L

L.ADDON_LOADED = "chargé"
L.ADDON_SLASH_HELP = "Tapez |cffff8800/chatbar|r pour les options."

L.CHAT_SAY = "Dire"
L.CHAT_YELL = "Crier"
L.CHAT_EMOTE = "Emote"
L.CHAT_WHISPER = "Chuchoter"
L.CHAT_PARTY = "Groupe"
L.CHAT_RAID = "Raid"
L.CHAT_RAID_WARNING = "Avertissement Raid"
L.CHAT_INSTANCE = "Instance"
L.CHAT_GUILD = "Guilde"
L.CHAT_OFFICER = "Officier"
L.CHAT_BATTLEGROUND = "Champ de bataille"

L.SETTINGS_TITLE = "Paramètres ChatBar"
L.VERSION = "Version"
L.PROFILE_MODE = "Mode de Profil:"
L.PROFILE_ACCOUNT = "Compte entier (partagé entre personnages)"
L.PROFILE_CHARACTER = "Paramètres par personnage"
L.BUTTON_THEME = "Thème de Bouton:"
L.BAR_THEME = "Thème de Barre:"
L.ORIENTATION = "Orientation:"
L.ORIENTATION_HORIZONTAL = "Horizontale"
L.ORIENTATION_VERTICAL = "Verticale"
L.ENABLED_CHANNELS = "Canaux Activés:"
L.NUMBERED_CHANNELS = "Canaux Numérotés:"
L.SHOW_NUMBERED_CHANNELS = "Afficher les canaux numérotés (Général, Commerce, etc.)"

L.MSG_BAR_SHOWN = "Barre affichée"
L.MSG_BAR_HIDDEN = "Barre masquée"
L.MSG_BAR_TOGGLED = "Barre"
L.MSG_RESET = "Réinitialisation aux valeurs par défaut..."
L.MSG_RESET_COMPLETE = "Paramètres réinitialisés!"
L.MSG_STILL_LOADING = "L'addon est toujours en cours de chargement, réessayez dans un moment."
L.MSG_SETTINGS_LOADING = "Le panneau de paramètres est toujours en cours de chargement, réessayez dans un moment."

L.TOOLTIP_CHANNEL = "Canal"
L.TOOLTIP_CHAT = "Chat"
L.TOOLTIP_CLICK_SWITCH = "Cliquez pour changer de canal"

L.CMD_HELP_HEADER = "Commandes:"
L.CMD_OPEN_SETTINGS = "Ouvrir les paramètres"
L.CMD_TOGGLE = "Basculer la visibilité de la barre"
L.CMD_SHOW = "Afficher la barre"
L.CMD_HIDE = "Masquer la barre"
L.CMD_RESET = "Réinitialiser aux valeurs par défaut"
L.CMD_HELP = "Afficher cette aide"
