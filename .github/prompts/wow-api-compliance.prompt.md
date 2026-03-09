---
description: "Check WoW addon code for API compliance issues, deprecated functions, TOC requirements, and best practices against the latest WoW API version. Reports issues with line numbers and modernization suggestions."
name: "WoW API Compliance Check"
argument-hint: "File path or selection to check"
agent: "agent"
---

# WoW Addon API Compliance Checker

Perform a comprehensive audit of WoW addon code for API compliance and best practices.

## Analysis Scope

**Check the following in order of priority:**

### 1. TOC File Requirements (if applicable)
- **Interface version**: Must match latest WoW API level (12.0.0+ = 120000, 12.0.1 = 120001, etc.)
- **Required fields**: Title, Version, Author metadata
- **File load order**: Dependencies between files (locales → skins → core → config)
- **SavedVariables**: Proper declaration for settings persistence
- **API compatibility tags**: ## OptionalDeps, ## RequiredDeps, ## X-Category

### 2. Deprecated API Calls
Identify and flag deprecated functions with modern replacements:

**Common Deprecations (WoW 10.0+):**
- `ChatEdit_UpdateHeader(editBox)` → `editBox:UpdateHeader()`
- `GetNumGroupMembers()` → Use with IsInRaid() to determine context
- `UnitHealthMax()` → `UnitHealth(unit, true)` for max
- `SendChatMessage()` → Requires hardware event (action bar, keybinding, or macro)
- `GetChannelList()` → Modern channel iteration patterns
- Direct `SLASH_COMMANDNAME` globals → Use SlashCmdList table

**Settings API (WoW 10.0+):**
- Old InterfaceOptions → `Settings.RegisterVerticalLayoutCategory()`
- InterfaceOptionsFrame_OpenToCategory → `Settings.OpenToCategory()`

### 3. Breaking Changes
Flag patterns that may cause errors:

- **Combat lockdown violations**: UI manipulation during combat
- **Taint issues**: Improper mixing of secure/insecure code
- **Missing nil checks**: API functions that changed return values
- **String library changes**: Functions moved or renamed
- **Event signature changes**: Updated event parameters

### 4. Modern API Best Practices
Recommend improvements for:

- **Frame creation**: Use frame pools for performance
- **Event handling**: Dispatcher pattern vs. monolithic OnEvent
- **Memory management**: Table reuse, proper wipe() usage
- **Namespace pollution**: Use of `local addonName, ns = ...` pattern
- **Hook patterns**: HookScript vs SetScript to avoid overwrites
- **C_* API usage**: Modern namespaced APIs vs legacy globals

### 5. Lua 5.1 Compatibility
WoW uses embedded Lua 5.1 - flag any:
- Lua 5.2+ syntax (goto, bitwise ops, etc.)
- Features not available in WoW's sandbox
- Incorrect metatable usage

## Output Format

For each issue found, provide:

```
📍 [Severity] File: Line X-Y
Issue: <Brief description>
Current: <code snippet>
Recommended: <modernized code>
Reason: <Why this matters>
```

**Severity Levels:**
- 🔴 **BREAKING**: Will cause errors/crashes
- 🟡 **DEPRECATED**: Works now but may break in future patches
- 🟢 **IMPROVEMENT**: Best practice or performance optimization
- 🔵 **INFO**: Informational suggestion

## Special Considerations

### For ChatBar Addon Specifically:
- Validate chat frame EditBox manipulation patterns
- Check channel detection logic (static vs numbered channels)
- Verify texture loading from skin folders
- Confirm Settings API usage (not legacy InterfaceOptions)
- Validate keybinding declarations in Bindings.xml

### Cross-File Dependencies:
- If TOC file is provided, validate load order matches dependencies
- Check that translation tables (ns.L) are loaded before use
- Ensure skin registry (ns.SkinRegistry) is populated before Textures.lua

## Analysis Steps

1. **Identify file type** (.lua, .toc, .xml)
2. **Scan for deprecated patterns** using regex and known API changes
3. **Check WoW API version context** from TOC or code comments
4. **Validate namespace usage** (local addonName, ns = ... pattern)
5. **Review event handlers** for proper registration
6. **Check combat safety** for UI manipulation
7. **Validate SavedVariables access** patterns
8. **Report findings** with line numbers and fixes

## Research Requirements

Before auditing:
1. Review latest WoW API documentation (current patch as of March 2026)
2. Check for recent hotfixes or breaking changes
3. Identify addon's target WoW version from TOC

After auditing:
- Prioritize issues by severity
- Summarize compliance status: "X breaking issues, Y deprecations, Z improvements"
- Provide migration guide if major updates needed

## Example Output

```
📍 🟡 DEPRECATED ChatBar.lua: Line 234
Issue: Using legacy ChatEdit_UpdateHeader() global function
Current: ChatEdit_UpdateHeader(editBox)
Recommended: editBox:UpdateHeader()
Reason: Global function deprecated in 10.0+, use EditBox method instead

📍 🔴 BREAKING Config.lua: Line 89
Issue: InterfaceOptionsFrame API removed in WoW 10.0
Current: InterfaceOptionsFrame_OpenToCategory(panel)
Recommended: Settings.OpenToCategory(category)
Reason: Legacy API removed, must migrate to Settings API

📍 🟢 IMPROVEMENT ChatBar.lua: Line 412
Issue: Creating frames without reusing from pool
Current: CreateFrame("Button", nil, parent) in loop
Recommended: Implement button pooling pattern (see lines 382-523)
Reason: Performance optimization for frequent frame creation
```

## Notes

- Focus on **actionable findings** with clear migration paths
- Consider addon's **target audience** (retail vs classic) if determinable
- Flag **false positives** with reasoning (e.g., "If supporting WoW 9.x, this is valid")
- Provide **documentation links** for complex migrations
