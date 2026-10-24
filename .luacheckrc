-- Luacheck covers accidental global writes, unused variables and shadowing.
-- Reads of WoW API globals (W113) are checked against real 12.x data by LuaLS
-- (Ketho annotations) and hated-wow-mcp's wow_lua_lint, so they are not
-- duplicated here as a hand-maintained list.
std = "lua51"
max_line_length = false
codes = true

ignore = {
	"113", -- accessing undefined variable (WoW API reads; see above)
	"212", -- unused argument (event handler and script signatures)
}

-- Globals the addon is allowed to create or modify. The BINDING_* strings are
-- written through _G[...], which luacheck does not track.
globals = {
	"ChatBarDB",
	"ChatBarCharDB",
	"SLASH_CHATBAR1",
	"SLASH_CHATBAR2",
	"SlashCmdList",
	-- Called from Bindings.xml, which runs in the global scope
	"ChatBar_ToggleBar",
	"ChatBar_SwitchToChannel",
	"ChatBar_QuickReplyLastWhisper",
	"ChatBar_CycleChannel",
}

exclude_files = {
	".claude/**", -- skill examples, not addon code
	".luals/**", -- LuaLS annotation stubs, never loaded by the game
	".luacheckrc",
}
