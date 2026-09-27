# ChatBar - World of Warcraft Addon

A lightweight, customizable chat channel switcher addon for World of Warcraft that displays quick-access buttons above your active chat frame.

## Supported Clients

ChatBar ships as a single package that loads on every current flavor:

| Client | Version | Interface |
| --- | --- | --- |
| Retail (Midnight) | 12.1.0 | 120100, 120007, 120005 |
| World of Warcraft: Forever | 1.60.1 | 16001 |
| Mists of Pandaria Classic | 5.5.4 | 50504 |
| Classic Era | 1.15.9 | 11509 |

Forever runs on the Midnight client codebase, so it behaves like Retail rather
than like Classic. The Classic clients share Blizzard's unified chat UI, so the
only flavor-specific code in ChatBar is the battleground check in
`ChatBar:IsChannelAvailable`.

## Release Notes

Release notes are published in [RELEASE_NOTES.md](RELEASE_NOTES.md).

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

### Appearance

ChatBar draws itself from **themes** rather than texture files -- every surface is
a colour or gradient generated at runtime, so the look stays crisp at any
resolution and UI scale.

- **Flat** -- channel-coloured plates, the active channel filled in, the rest
  sitting back at low alpha, and one accent rule running under the whole bar
- **Glass** -- the same design rendered as glass: each plate a gradient lit from
  above, with a sheen across the top third and a rim that catches the accent

Both themes colour every channel with its own hue, normalised to a fixed
perceptual luminance so a row of eight channels reads as eight colours at one
brightness rather than the glare-and-mud of the raw `ChatTypeInfo` palette.
Numbered channels are deliberately left uncoloured -- they read as one neutral
group instead of competing with the named channels around them.

**Button shape** belongs to the theme. Both ship square by default, which is
what makes them read as one design in two finishes. Flat is a tab strip and
fixes that -- its control greys out. Glass survives being reshaped, so it keeps
a square-or-round choice.

The **accent colour** defaults to your class colour and marks whichever channel
the chat box is currently pointed at. The settings panel shows a live preview
drawn by the same engine that draws the real bar.

#### Fonts

Two choices:

- **Default** -- the client's own UI face. Resolved through a Blizzard font
  object rather than a file path, so it is the right face in every language.
- **Expressway** -- bundled with the addon (`Media/Expressway.ttf`). Expressway
  Free by Ray Larabie, freeware, covering Latin, Latin-1 and the full Cyrillic
  alphabet.

Expressway carries no CJK glyphs, so on Korean and Chinese clients it falls back
to the Default face rather than drawing a row of empty boxes. Every other locale,
Russian included, renders natively.

#### Adding a theme

1. Create `Themes/YourTheme.lua` and register it into `ns.ThemeRegistry`
2. Add the file to `ChatBar.toc` above `Design.lua`
3. Add `THEME_YOURTHEME` / `THEME_YOURTHEME_DESC` keys to `Locales/Locales.lua`

Copy `Themes/Flat.lua` for the full token schema. Colour tokens are
`{ r, g, b, a }` and may carry an `accent = true` or `channel = true` marker,
plus optional `lighten` / `darken`, which the engine resolves at paint time.

### Localization

- **Supported Languages**: English (enUS), German (deDE), Spanish (esES), French (frFR), Russian (ruRU)
- **UTF-8 Support**: Full multi-byte character support for Cyrillic, Asian, and other multi-byte character sets
- **Auto-detection**: Uses your WoW client's language automatically
- **Fallback System**: Defaults to English if translation missing
- **Smart Text Extraction**: Properly handles first-character extraction for all languages

### SavedVariables

- `ChatBarDB` - Account-wide settings (shared across all characters)
- `ChatBarCharDB` - Per-character settings (unique to each character)

### Performance

- **Lightweight**: Minimal memory footprint (~100KB)
- **Event-driven**: Only updates when game state changes
- **No continuous polling**: Uses WoW's event system efficiently
- **No texture files**: Themes are pure Lua, drawn with the engine's own colour and gradient calls
- **Object pooling**: Reuses button frames and their texture stacks across rebuilds

## Advanced

### File Structure

```MD
ChatBar/
├── ChatBar.lua          # Main addon logic
├── ChatBar.toc          # Addon manifest
├── ChatBar.tga          # Addon icon
├── Design.lua           # Design engine: paints the bar and buttons
├── Config.lua           # Settings panel UI
├── README.md            # Documentation
├── Core/
│   ├── Pixel.lua        # Pixel-perfect geometry and the 1px border primitive
│   └── Theme.lua        # Theme tokens, accent resolution, colour helpers
├── Media/
│   └── Expressway.ttf   # Bundled label font (Latin only)
├── Themes/
│   ├── Flat.lua         # Channel-coloured plates, accent rule under the bar
│   └── Glass.lua        # The same design in lit glass, with an accent rim
└── Locales/
    ├── Locales.lua      # English (base)
    ├── deDE.lua         # German
    ├── esES.lua         # Spanish
    ├── frFR.lua         # French
    ├── ruRU.lua         # Russian
    └── koKR.lua         # Korean
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

## Release Process (For Maintainers)

ChatBar uses automated publishing to CurseForge via GitHub Actions.

### Creating a New Release

1. **Ensure all changes are committed** and pushed to the main branch
2. **Create an annotated Git tag** with the version number:
   ```bash
   git tag -a v2.3.0 -m "Release 2.3.0"
   ```
3. **Push the tag** to trigger the release workflow:
   ```bash
   git push origin v2.3.0
   ```
4. **Monitor the workflow** at https://github.com/YOUR-USERNAME/chatbar/actions
5. **Verify the release**:
   - Check CurseForge project page for the new version
   - Review the auto-generated changelog from commit messages

### Version Numbering

- **Stable releases**: `v2.3.0`, `v2.4.0`, `v3.0.0`
- **Beta releases**: `v2.3.0-beta`, `v2.3.0-beta.2` (marked as beta on CurseForge)
- **Alpha releases**: `v2.3.0-alpha`, `v3.0.0-alpha.1` (marked as alpha on CurseForge)

### Changelog Best Practices

The packager automatically generates changelogs from Git commits between tags. Write commit messages for end users:

- ✅ Good: "Fix memory leak in button pooling", "Add Korean translation", "Update TOC to 11.0.5"
- ❌ Avoid: "fix", "wip", "updates", "misc changes"

### What Gets Published

The following files are included in the CurseForge package:
- All `.lua` and `.xml` files
- `ChatBar.toc` (with version automatically updated from tag)
- `Bindings.xml`
- All files in `Locales/`, `Core/` and `Themes/` directories

The following are excluded:
- `.github/` directory (except workflow runs)
- `.vscode/` directory
- `README.md`
- `.gitignore`, `.pkgmeta`

## License

This addon is free software provided as-is for World of Warcraft players. Feel free to modify and distribute with attribution.
