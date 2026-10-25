-- Profile.Confirm: profile select moves on once every joined player confirmed.
-- Pure Lua.
--
-- The engine's own confirm (ScreenSelectProfile:Finish) treats index 0 as a
-- memory card and refuses to finish without one, so a guest next to a profile
-- could not be confirmed and the theme moved on with no profile loaded at all.
-- The theme loads the profiles itself instead: it sets each player's default
-- local profile ID ("" for a guest) and calls GAMESTATE:LoadProfiles().
--
--   Plan(players) -> nil while someone is not ready, else
--       { AllGuest = bool, DefaultIDs = { [pn] = "00000000" | "" } }
--       players = { [pn] = { Ready = bool, Index = engine index (0 = guest), ID = local profile ID } }
--   Allowed(index, otherIndex) -> false when the other player already holds that profile
--   StyleAfterDrop(styleType) -> "single" when a two-player style is set, else nil
--       A player joining from song select sets versus, and under a two-player style the
--       engine still counts a player who unjoined as human (GAMESTATE:IsHumanPlayer
--       follows the style once there is one), so a dropped player stayed on screen and
--       profile select waited for them.

local Confirm = {}

function Confirm.Plan(players)
    local Plan = { AllGuest = true, DefaultIDs = {} }
    for pn, P in pairs(players) do
        if not P.Ready then return nil end
        if P.Index and P.Index > 0 and P.ID then
            Plan.AllGuest = false
            Plan.DefaultIDs[pn] = P.ID
        else
            Plan.DefaultIDs[pn] = ""
        end
    end
    return Plan
end

function Confirm.Allowed(index, otherIndex)
    return index == 0 or otherIndex == nil or index ~= otherIndex
end

local TWO_PLAYERS = { StyleType_TwoPlayersTwoSides = true, StyleType_TwoPlayersSharedSides = true }

function Confirm.StyleAfterDrop(styleType)
    return TWO_PLAYERS[styleType] and "single" or nil
end

return Confirm
