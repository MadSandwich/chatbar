# ChatBar - World of Warcraft Addon

A customizable chat channel switcher addon for World of Warcraft that displays quick-access buttons above your active chat frame.

## Features

### Dynamic Channel Detection

- **Automatic availability** - Buttons appear only for channels you currently have access to
- **Guild chat** - Shows when you're in a guild
- **Party chat** - Shows when you're in a party (but not raid)
- **Raid chat** - Shows when you're in a raid group
- **Battleground chat** - Shows when you're in an active battleground
- **Instance chat** - Shows when in dungeon/scenario groups
- **Numbered channels** - Auto-detects General, Trade, LocalDefense, and custom channels
- **Always available** - Say, Yell, Emote, and Whisper buttons (configurable)

### Active Chat Frame Tracking

- Buttons automatically follow whichever chat window has focus
- Works with all chat frames (ChatFrame1-10)
- Repositions when you switch between chat windows

### Customizable Appearance

#### Button Themes (3 Presets)

- **Classic** - Traditional WoW button style (28px, silver buttons)
- **Modern** - Clean contemporary look (32px, frame-style buttons)
- **Minimal** - Compact colored backgrounds (24px, no textures)

#### Bar Themes (3 Presets)

- **Classic** - Dialog box style with tooltip borders
- **Modern** - Sleek dark design with subtle borders
- **Minimal** - Transparent background, no borders

#### Layout Options

- **Horizontal** - Buttons arranged in a row (default)
- **Vertical** - Buttons stacked in a column

### Channel Configuration

- **Enable/Disable** - Toggle individual channels on/off
- **Numbered channels** - Choose to show/hide General, Trade, etc.
- **Channel filtering** - Configure which specific numbered channels to display

### Profile System

- **Account-wide** - Share settings across all characters (default)
- **Per-character** - Unique settings for each character
- Easily switch between modes in settings

### Additional Features

- **Draggable bar** - Reposition manually by dragging
- **Toggle visibility** - Keybind or command to show/hide entire bar
- **Color-coded buttons** - Uses WoW's chat type colors for easy identification
- **Tooltips** - Hover over buttons for channel information
- **Slash commands** - Quick access to all features

## Installation

1. Download or clone this repository
2. Copy the `ChatBar` folder to your WoW AddOns directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or reload UI (`/reload`)
4. Enable "ChatBar" in the AddOns list

## Usage

### Slash Commands

- `/chatbar` or `/cb` - Open settings panel
- `/chatbar toggle` - Toggle bar visibility
- `/chatbar show` - Show the bar
- `/chatbar hide` - Hide the bar
- `/chatbar reset` - Reset all settings to defaults
- `/chatbar help` - Display help information

### Keybinds

Set a keybind for "Toggle ChatBar" in:

- ESC → Keybinds → AddOns → ChatBar

### Settings Panel

Access via:

- `/chatbar` command
- Interface → AddOns → ChatBar

#### Available Settings

##### Profile Mode

- Account-wide (shared across characters)
- Per-character (unique per character)

##### Button Theme

- Classic, Modern, or Minimal

##### Bar Theme

- Classic, Modern, or Minimal

##### Orientation

- Horizontal or Vertical

##### Enabled Channels

- Checkboxes for each channel type
- Toggle for numbered channels

## How It Works

### Channel Switching

1. Click any button to switch to that chat channel
2. The chat input box updates to the selected channel
3. Input box automatically receives focus
4. Start typing immediately

### Channel Availability

The addon monitors game events to show/hide buttons:

- **Guild joined/left** - Guild/Officer buttons appear/disappear
- **Group formed/disbanded** - Party/Raid buttons update
- **Battleground entered/exited** - BG button updates
- **Channels joined/left** - Numbered channel buttons update

### Theme System

- **Button themes** control button appearance (size, textures, colors)
- **Bar themes** control container appearance (background, borders, padding)
- Themes can be mixed independently
- Uses WoW's built-in ChatTypeInfo colors for authentic look

## Technical Details

### Compatibility

- **Interface Version**: 120000 (Patch 12.0.0+)
- **Game Version**: World of Warcraft Retail - Midnight expansion (Patch 12.0.0.65560+)
- **API Compatibility**: Fully compatible with patch 12.0.0 and 12.0.1 API changes
  - Uses modern BackdropTemplate mixin system
  - All chat APIs used are current and not deprecated
  - Does not use any removed or deprecated functions
  - Not affected by secret values system (non-combat addon)

### SavedVariables

- `ChatBarDB` - Account-wide settings
- `ChatBarCharDB` - Per-character settings

### Events Monitored

- `PLAYER_ENTERING_WORLD` - Initial setup
- `GROUP_ROSTER_UPDATE` - Party/raid changes
- `PLAYER_GUILD_UPDATE` - Guild status changes
- `GUILD_ROSTER_UPDATE` - Guild roster updates
- `CHANNEL_UI_UPDATE` - Channel list changes
- `ZONE_CHANGED_NEW_AREA` - Zone changes (battlegrounds)
- `UPDATE_CHAT_WINDOWS` - Chat frame repositioning

### API Usage

- `IsInGuild()` - Guild membership detection
- `IsInGroup()` - Party detection
- `IsInRaid()` - Raid detection
- `C_PvP.IsActiveBattlefield()` - Battleground detection
- `GetChannelList()` - Numbered channel detection
- `ChatEdit_UpdateHeader()` - Chat channel switching

## Troubleshooting

### Buttons not appearing

- Check if channels are enabled in settings (`/chatbar`)
- Verify you actually have access to those channels (in guild, party, etc.)
- Try `/reload` to refresh the addon

### Bar not following chat frame

- Make sure a chat editbox has focus
- Try clicking in the chat input box
- Check if bar visibility is enabled (`/chatbar show`)

### Settings not saving

- Check SavedVariables are enabled in WoW settings
- Verify addon is loaded properly
- Try `/chatbar reset` then reconfigure

### Interface version error

- Addon requires WoW Retail (The War Within, patch 12.0.0+)
- Not compatible with Classic Era or Classic Wrath

## Customization

### Adding Custom Channels

The addon automatically detects numbered channels. To filter specific ones:

1. Open settings (`/chatbar`)
2. Enable/disable "Numbered Channels"
3. Addon will detect all joined channels

### Adjusting Position

- **Manual**: Drag the bar with left mouse button
- **Automatic**: Bar follows active chat frame focus

## Support & Contribution

### Reporting Issues

Please report bugs or feature requests with:

- WoW version and build number
- Addon version
- Steps to reproduce
- Error messages (if any)

### Feature Requests

Suggestions for new features are welcome!

## License

This addon is provided as-is for World of Warcraft players.
