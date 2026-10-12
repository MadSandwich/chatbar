-- ChatBar: HUD Edit Mode integration
--
-- Puts the bar into Blizzard's Edit Mode next to the frames Blizzard ships:
-- highlighted while Edit Mode is open, draggable, and selectable, which opens
-- its settings dialog (EditModeDialog.lua).
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

local addonName, ns = ...

local EditMode = {}
ns.EditMode = EditMode

-- Shown on the selection label, its tooltip and the settings dialog title. The
-- addon's name, not a translatable string, and plain: L.ADDON_NAME carries a
-- color code.
EditMode.NAME = "ChatBar"

local bar
local selection
local dragging = false

-- Retail and Forever only. Both are the Mainline family and run the same Edit
-- Mode code. The Classic clients ship a port of it too, but they are out of
-- scope for now, so the family is checked on purpose rather than the frame alone.
function EditMode:IsSupported()
    return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
        and EditModeManagerFrame ~= nil
        and EditModeManagerFrame.IsEditModeActive ~= nil
        and EditModeManagerFrame.ClearSelectedSystem ~= nil
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

function EditMode:ShowSelection()
    selection = selection or CreateSelection()
    selection:ShowHighlighted()
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
end

-- Hook the bar into Edit Mode. Called once, after the bar frame exists; the
-- selection overlay itself is only built the first time Edit Mode opens.
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
            EditMode:ShowSelection()
        end
    end)
    EditModeManagerFrame:HookScript("OnHide", function()
        EditMode:HideSelection()
    end)

    -- Selecting any other frame, Blizzard's or another addon's, drops the bar
    -- back to highlighted. Post-hooks only, so the originals stay secure.
    hooksecurefunc(EditModeManagerFrame, "SelectSystem", function()
        EditMode:Deselect()
    end)
    hooksecurefunc(EditModeManagerFrame, "ClearSelectedSystem", function()
        EditMode:Deselect()
    end)
end
