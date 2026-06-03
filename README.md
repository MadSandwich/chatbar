# ChatBar - World of Warcraft Addon

A lightweight, customizable chat channel switcher addon for World of Warcraft that displays quick-access buttons above your active chat frame.

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
- **Texture caching**: Reuses button objects from pool

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
- All files in `Locales/` and `Skins/` directories

The following are excluded:
- `.github/` directory (except workflow runs)
- `.vscode/` directory
- `README.md`
- `.gitignore`, `.pkgmeta`

## License

This addon is free software provided as-is for World of Warcraft players. Feel free to modify and distribute with attribution.
