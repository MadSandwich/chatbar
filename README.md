# ChatBar - World of Warcraft Addon

A lightweight, customizable chat channel switcher addon for World of Warcraft that displays quick-access buttons above your active chat frame.

## Features

### Dynamic Channel Detection

- **Automatic availability** - Buttons appear only for channels you currently have access to (Guild chat, Party chat, Raid chat, Battleground chat, Instance chat)
- **Numbered channels** - Auto-detects General, Trade, LocalDefense, and custom channels
- **Always available** - Say, Yell, Emote, and Whisper buttons (configurable)

### Customizable Appearance

#### Button Themes (3 Presets)

- **Classic** - Traditional WoW button style (24px, silver-gray buttons with borders)
- **Modern** - Clean contemporary look (24px, dark frame-style buttons with subtle borders)
- **Minimal** - Compact transparent design (24px, no borders, blend-in look)

#### Bar Themes (3 Presets)

- **Classic** - Dialog box style with tooltip borders (gold/silver theme)
- **Modern** - Sleek dark design with subtle blue borders
- **Minimal** - Transparent background, no visible borders

#### Typography

- **Adjustable Font Size** - Slider to customize button text size (8-24px, default: 12px)
- **UTF-8 Support** - Full support for Cyrillic, Asian, and other multi-byte character sets
- **Localized Labels** - Automatically uses your WoW client's language for channel names
- **Smart Text Display** - Shows first letter of channel name (S=Say, Y=Yell) or channel number

#### Layout Options

- **Horizontal** - Buttons arranged in a row (default)
- **Vertical** - Buttons stacked in a column

### Profile System

- **Account-wide** - Share settings across all characters (default)
- **Per-character** - Unique settings for each character

### Additional Features

- **Draggable Bar** - Click and drag to reposition manually
- **Lock Position** - Prevent accidental movement when locked
- **Toggle Visibility** - Keybind or command to show/hide entire bar
- **Color-coded Buttons** - Uses WoW's native chat type colors for easy identification
- **Tooltips** - Hover over buttons for channel information
- **Slash Commands** - Quick access to all features via console

## Usage

### Slash Commands

- `/chatbar` or `/cb` - Open settings panel
- `/chatbar toggle` - Toggle bar visibility
- `/chatbar show` - Show the bar
- `/chatbar hide` - Hide the bar
- `/chatbar reset` - Reset all settings to defaults
- `/chatbar help` - Display help information

### Settings Panel

Access via:

- `/chatbar` or `/cb` command
- Interface → AddOns → ChatBar
- Game Menu (ESC) → Interface → AddOns → ChatBar

### Localization

- **Supported Languages**: English (enUS), German (deDE), Spanish (esES), French (frFR), Russian (ruRU)
- **UTF-8 Support**: Full multi-byte character support for Cyrillic, Asian, and other multi-byte character sets
- **Auto-detection**: Uses your WoW client's language automatically
- **Fallback System**: Defaults to English if translation missing
- **Smart Text Extraction**: Properly handles first-character extraction for all languages

### SavedVariables

- `ChatBarDB` - Account-wide settings (shared across all characters)
- `ChatBarCharDB` - Per-character settings (unique to each character)

### Events Monitored

- `PLAYER_ENTERING_WORLD` - Initial setup and world transitions
- `GROUP_ROSTER_UPDATE` - Party/raid composition changes
- `PLAYER_GUILD_UPDATE` - Guild membership status changes
- `GUILD_ROSTER_UPDATE` - Guild roster updates
- `CHANNEL_UI_UPDATE` - Channel list changes (numbered channels)
- `ZONE_CHANGED_NEW_AREA` - Zone changes (battlegrounds)
- `UPDATE_CHAT_WINDOWS` - Chat frame repositioning

### API Usage

- **Chat Detection**: `IsInGuild()`, `IsInGroup()`, `IsInRaid()`, `C_PvP.IsActiveBattlefield()`
- **Channel Management**: `GetChannelList()`, `ChatEdit_UpdateHeader()`
- **Frame Management**: `CreateFrame()`, `BackdropTemplate`
- **Texture System**: `SetColorTexture()`, `SetAllPoints()`
- **Font Rendering**: `CreateFontString()`, `SetFont()`, UTF-8 string manipulation

### Performance

- **Lightweight**: Minimal memory footprint (~100KB)
- **Event-driven**: Only updates when game state changes
- **No continuous polling**: Uses WoW's event system efficiently
- **Texture caching**: Reuses button objects from pool

## Troubleshooting

### Buttons not appearing

- **Check settings**: Ensure channels are enabled in `/chatbar` settings
- **Verify access**: Confirm you have access to those channels (in guild, party, battleground, etc.)
- **Reload UI**: Try `/reload` to refresh the addon
- **Check numbered channels**: For General/Trade, ensure "Show Numbered Channels" is enabled

### Text not visible on buttons

- **Font size**: Adjust font size slider in settings (8-24px range)
- **Text color**: Buttons use chat type colors or white - check theme settings
- **UTF-8 characters**: If using Cyrillic or Asian characters, ensure latest version is installed
- **Reload required**: After changing font settings, `/reload` may be needed

### Settings not saving

- **SavedVariables**: Verify SavedVariables are enabled in WoW settings
- **Addon loaded**: Check addon is enabled in character select screen
- **Profile mode**: If sharing settings isn't working, check profile mode (account vs character)
- **Reset option**: Try `/chatbar reset` then reconfigure from scratch

### Interface version error

- Addon requires **WoW Retail** (Midnight expansion, patch 12.0.0+)
- **Not compatible** with Classic Era or Classic Wrath

## Advanced

### File Structure

```MD
ChatBar/
├── ChatBar.lua          # Main addon logic
├── ChatBar.toc          # Addon manifest
├── ChatBar.tga          # Addon icon
├── Config.lua           # Settings panel UI
├── README.md            # Documentation
└── Locales/
    ├── Locales.lua      # English (base)
    ├── deDE.lua         # German
    ├── esES.lua         # Spanish
    ├── frFR.lua         # French
    └── ruRU.lua         # Russian
```

### Extending Localization

To add a new language:

1. Create `Locales/xxXX.lua` (e.g., `zhCN.lua` for Chinese)
2. Add to `ChatBar.toc` file list
3. Copy structure from `Locales.lua`
4. Translate all strings
5. Submit as contribution

## Support & Contribution

### Reporting Issues

When reporting bugs, please include:

- **WoW Version**: Game patch number (e.g., 12.0.0.65560)
- **Addon Version**: ChatBar version (shown in `/chatbar`)
- **Steps to Reproduce**: Clear description of what you did
- **Expected vs Actual**: What should happen vs what actually happens
- **Error Messages**: Any Lua errors from BugSack or similar addon
- **Other Addons**: List of other chat addons installed

### Feature Requests

Feature suggestions are welcome! Prioritization based on:

- Community interest
- Technical feasibility
- Alignment with addon purpose (lightweight chat channel switcher)

### Contributing

Contributions welcome via:

- Bug reports and testing
- Localization translations
- Code improvements
- Documentation updates

## License

This addon is free software provided as-is for World of Warcraft players. Feel free to modify and distribute with attribution.
