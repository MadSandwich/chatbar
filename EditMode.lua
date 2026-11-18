-- ChatBar: HUD Edit Mode integration
--
-- Puts the bar into Blizzard's Edit Mode next to the frames Blizzard ships:
-- shown as a highlighted block in place of its buttons while Edit Mode is open,
-- draggable, and selectable, which opens its settings dialog
-- (EditModeDialog.lua). A "ChatBar" checkbox docked under the manager takes the
-- bar in and out of Edit Mode, the way the manager's own checkboxes do for
-- Blizzard's frames.
--
-- The bar is deliberately *not* an Edit Mode system. Systems are registered
-- with the manager, saved into its server-side layouts and driven through
-- secure code, none of which an addon frame can join without tainting it.
-- The bar borrows the system selection template for the look and does the
-- rest itself, which has two consequences worth knowing:
--   * the position is saved to the ChatBar profile the moment the bar is
--     dropped, so switching Edit Mode layouts or reverting changes leaves the
--     bar where it is, and
--   * the position lock is ignored here. The lock guards against a stray drag
--     in play; Edit Mode is the one place the player is arranging the UI.

local _, ns = ...

local EditMode = {}
ns.EditMode = EditMode

-- Shown on the selection label, its tooltip, the manager checkbox and the
-- settings dialog title. The addon's name, not a translatable string, and
-- plain: L.ADDON_NAME carries a color code.
EditMode.NAME = "ChatBar"

local bar
local selection
local dragging = false
-- Edit Mode is open with its manager showing. False again while another panel
-- is open over Edit Mode: the manager hides then, and so does everything here.
local active = false

-- Retail and Forever: both run Mainline's UI code, Edit Mode included. Forever
-- reports a project of its own, WOW_PROJECT_CAMELOT (18; seen in game
-- 2026-11-15), which only Forever's Blizzard_ProjectConstants defines, so
-- WOW_PROJECT_MAINLINE alone misses it. (C_GameRules.IsWoWHack is a different
-- game mode and returns false on Forever.)
local function IsMainlineFamily()
    return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
        or (WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
end

-- The Classic clients ship a port of Edit Mode too, but they are out of scope
-- for now, so the family is checked on purpose rather than the frame alone.
function EditMode:IsSupported()
    return IsMainlineFamily()
        and EditModeManagerFrame ~= nil
        and EditModeManagerFrame.IsEditModeActive ~= nil
        and EditModeManagerFrame.ClearSelectedSystem ~= nil
end

-- Whether the bar takes part in Edit Mode: the manager checkbox's state.
function EditMode:IsBarIncluded()
    return ns.ChatBar:GetSettings().editModeShown ~= false
end

local function StopDrag()
    if not dragging then return end
    dragging = false
    bar:StopMovingOrSizing()
    ns.ChatBar:SaveBarPosition()
    -- A saved position is what enables the dialog's reset button.
    ns.EditModeDialog:Refresh()
end

local function CreateSelection()
    local frame = CreateFrame("Frame", nil, bar, "EditModeSystemSelectionTemplate")
    frame:SetAllPoints(bar)
    frame:Hide()

    -- The template reads its label and tooltip text off a system object. The
    -- bar has none, so hand it the one method the template calls.
    frame:SetSystem({ GetSystemName = function() return EditMode.NAME end })

    -- The template's own handlers route through EditModeManagerFrame, which
    -- only knows its registered systems. Replace all three.
    frame:SetScript("OnMouseDown", function()
        EditMode:Select()
    end)
    frame:SetScript("OnDragStart", function()
        dragging = true
        bar:StartMoving()
    end)
    frame:SetScript("OnDragStop", StopDrag)

    return frame
end

-- Mark the bar selected and open its settings, the way a Blizzard frame
-- behaves when clicked.
function EditMode:Select()
    if not selection or selection:IsSelected() then return end

    -- Drop whatever else is selected and close its settings dialog, so only
    -- one thing ever reads as selected. Out of combat the manager runs this
    -- through a secure delegate, which is what makes it safe from addon code.
    -- In combat it falls back to walking the action bars from the caller's
    -- tainted context, so leave Blizzard's selection alone there.
    if not InCombatLockdown() then
        EditModeManagerFrame:ClearSelectedSystem()
    end
    selection:ShowSelected()
    ns.EditModeDialog:Open()
end

-- Back to highlighted, with the settings dialog closed. Also runs from the
-- dialog's OnHide, so closing the dialog and deselecting are one and the same;
-- the second pass through here finds nothing left to do.
function EditMode:Deselect()
    if selection and selection:IsSelected() then
        selection:ShowHighlighted()
    end
    ns.EditModeDialog:Close()
end

-- While the bar takes part in Edit Mode its own surfaces and buttons are
-- invisible and only the selection block shows, the way Blizzard draws a frame
-- it has no live content for. The block stays opaque because the template sets
-- ignoreParentAlpha. Alpha rather than Hide: the selection is the bar's child
-- and would hide with it. Nothing else sets the bar frame's own alpha (Design
-- fades buttons and textures only), so HideSelection restores a plain 1.
function EditMode:ShowSelection()
    selection = selection or CreateSelection()
    selection:ShowHighlighted()
    bar:SetAlpha(0)
end

function EditMode:HideSelection()
    if not selection then return end
    -- Closing Edit Mode mid-drag (Escape with the button still held) would
    -- otherwise leave the bar glued to the cursor with nothing to release it.
    StopDrag()
    -- Deselect before hiding: ShowHighlighted shows the overlay, so running
    -- it afterwards (from the dialog's OnHide) would bring it back.
    self:Deselect()
    selection:Hide()
    bar:SetAlpha(1)
end

-- Bring the bar's Edit Mode state in line with the checkbox.
function EditMode:ApplyIncluded()
    if not active then return end
    if self:IsBarIncluded() then
        self:ShowSelection()
    else
        self:HideSelection()
    end
end

--[[ The manager panel

    Holds the checkbox. It is a frame of ChatBar's own, docked to the manager
    and never parented into it: the manager walks its settingsCheckButtons
    with pairs, so an addon's entry there taints Edit Mode for every frame.

    Other addons dock panels to the manager the same way (WIM does, with a
    2px gap), anchored TOP to the manager's BOTTOM or to the panel above them.
    This one hangs off the end of that chain instead of covering it, and goes
    above the manager when there is no room below, as WIM's does.
]]

local PANEL_GAP = 2
local PANEL_INSET = 20
local PANEL_PADDING = 10
local ROW_HEIGHT = 32 -- EditModeManagerSettingCheckButtonTemplate's height
local MAX_CHAIN = 8 -- Docked panels to follow before giving up

local panel
local checkbox
-- What the current dock was computed from; a change in any of it re-docks.
local dockAnchor, managerTop, managerBottom, anchorTop, anchorBottom

-- True when `frame` hangs off `anchor`: its top edge on the anchor's bottom
-- (below), or its bottom edge on the anchor's top (above).
local function HangsOff(frame, anchor, below)
    if frame == panel or not frame:IsShown() then return false end
    local point, relativeTo, relativePoint = frame:GetPoint(1)
    if relativeTo ~= anchor or not point or not relativePoint then return false end
    if below then
        return point:find("^TOP") ~= nil and relativePoint:find("^BOTTOM") ~= nil
    end
    return point:find("^BOTTOM") ~= nil and relativePoint:find("^TOP") ~= nil
end

-- The last frame in the chain of panels hanging off the manager on one side,
-- or the manager itself when nothing hangs there.
local function ChainEnd(below)
    local children = { UIParent:GetChildren() }
    local anchor = EditModeManagerFrame
    for _ = 1, MAX_CHAIN do
        local nextAnchor
        for i = 1, #children do
            -- Another addon's frame can be forbidden, or anchored in ways addon
            -- code may not read. Skip it rather than error out of Edit Mode.
            local ok, hangs = pcall(HangsOff, children[i], anchor, below)
            if ok and hangs then
                nextAnchor = children[i]
                break
            end
        end
        if not nextAnchor then break end
        anchor = nextAnchor
    end
    return anchor
end

local function Dock()
    local manager = EditModeManagerFrame
    panel:SetScale(manager:GetScale())
    panel:SetWidth(manager:GetWidth())

    -- Compared in screen pixels: the panels in the chain need not share a scale.
    local anchor = ChainEnd(true)
    local bottom = anchor:GetBottom()
    local needed = (panel:GetHeight() + PANEL_GAP) * panel:GetEffectiveScale()
    panel:ClearAllPoints()
    if bottom and bottom * anchor:GetEffectiveScale() < needed then
        anchor = ChainEnd(false)
        panel:SetPoint("BOTTOM", anchor, "TOP", 0, PANEL_GAP)
    else
        panel:SetPoint("TOP", anchor, "BOTTOM", 0, -PANEL_GAP)
    end

    dockAnchor = anchor
    managerTop, managerBottom = manager:GetTop(), manager:GetBottom()
    anchorTop, anchorBottom = anchor:GetTop(), anchor:GetBottom()
end

-- Runs every frame while Edit Mode is open, so it only compares. The manager
-- changes height when its list is expanded or collapsed, and a neighbour can
-- then flip above it or hide.
local function DockIfMoved()
    local manager = EditModeManagerFrame
    if manager:GetTop() ~= managerTop or manager:GetBottom() ~= managerBottom
        or dockAnchor:GetTop() ~= anchorTop or dockAnchor:GetBottom() ~= anchorBottom
        or not dockAnchor:IsShown() then
        Dock()
    end
end

local function CreatePanel()
    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(100)
    -- Clicks on the padding must not fall through to the world.
    panel:EnableMouse(true)
    panel:SetHeight(2 * PANEL_PADDING + ROW_HEIGHT)
    panel:Hide()

    local border = CreateFrame("Frame", nil, panel, "DialogBorderTranslucentTemplate")
    border:SetAllPoints()

    checkbox = CreateFrame("Frame", nil, panel, "EditModeManagerSettingCheckButtonTemplate")
    checkbox:ClearAllPoints()
    checkbox:SetPoint("TOPLEFT", PANEL_INSET, -PANEL_PADDING)
    checkbox:SetLabelText(EditMode.NAME)
    -- SetControlChecked reports through here too, with isUserInput false.
    checkbox:SetCallback(function(checked, isUserInput)
        if not isUserInput then return end
        ns.ChatBar:GetSettings().editModeShown = checked
        EditMode:ApplyIncluded()
    end)

    panel:SetScript("OnUpdate", DockIfMoved)
end

local function ShowPanel()
    if not panel then CreatePanel() end
    checkbox:SetControlChecked(EditMode:IsBarIncluded())
    panel:Show()
    Dock()
    -- Other addons show their panels from the same manager OnShow, possibly
    -- after this hook ran. Dock again once they all have.
    C_Timer.After(0, function()
        if panel:IsShown() then Dock() end
    end)
end

-- The profile in effect was replaced (a mode switch or /chatbar reset) while
-- Edit Mode may be open.
function EditMode:Refresh()
    if not (active and checkbox) then return end
    checkbox:SetControlChecked(self:IsBarIncluded())
    self:ApplyIncluded()
end

local function Enter()
    active = true
    ShowPanel()
    EditMode:ApplyIncluded()
end

local function Exit()
    active = false
    if panel then panel:Hide() end
    EditMode:HideSelection()
end

-- Hook the bar into Edit Mode. Called once, after the bar frame exists; the
-- selection overlay and the manager panel are only built the first time Edit
-- Mode opens.
function EditMode:Attach(barFrame)
    if bar or not self:IsSupported() then return end
    bar = barFrame

    -- Edit Mode is entered from the manager's OnShow and left from its OnHide.
    -- Following the frame rather than the EditMode.Enter/Exit callbacks also
    -- covers the case those miss: when another panel opens over Edit Mode,
    -- the manager hides every selection without leaving, and restores them
    -- when it comes back.
    EditModeManagerFrame:HookScript("OnShow", function(manager)
        if manager:IsEditModeActive() then
            Enter()
        end
    end)
    EditModeManagerFrame:HookScript("OnHide", Exit)

    -- Selecting any other frame, Blizzard's or another addon's, drops the bar
    -- back to highlighted. Post-hooks only, so the originals stay secure.
    hooksecurefunc(EditModeManagerFrame, "SelectSystem", function()
        EditMode:Deselect()
    end)
    hooksecurefunc(EditModeManagerFrame, "ClearSelectedSystem", function()
        EditMode:Deselect()
    end)
end
