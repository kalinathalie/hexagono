-- Title.Input: pad logic of the title screen, as on the arcade. Pure Lua.
--
--   New() -> state
--   Press(state, pn, button, now) -> "join" | "start" | "options" | nil
--
-- The center panel (or Start) joins a player; a second press by a joined
-- player starts the game, so the other side can join in between. Red left,
-- red right, blue left, blue right, twice, with less than CodeGap seconds
-- between panels, opens the operator options. Each player has their own code
-- progress; a wrong panel restarts it (and counts as its first step when it is
-- the first panel of the code), a center press clears it.

local Title = {}

local CENTER = { Center = true, Start = true, MenuStart = true }
local CODE = { "UpLeft", "UpRight", "DownLeft", "DownRight", "UpLeft", "UpRight", "DownLeft", "DownRight" }
local CodeGap = 2

function Title.New()
    return { Joined = {}, Step = {}, Last = {} }
end

local function Advance(S, pn, button, now)
    local Step = S.Step[pn] or 0
    if Step > 0 and S.Last[pn] and now - S.Last[pn] > CodeGap then Step = 0 end
    if CODE[Step + 1] == button then
        Step = Step + 1
    else
        Step = (CODE[1] == button) and 1 or 0
    end
    S.Last[pn] = now
    if Step == #CODE then
        S.Step[pn] = 0
        return true
    end
    S.Step[pn] = Step
    return false
end

function Title.Press(S, pn, button, now)
    if CENTER[button] then
        S.Step[pn] = 0
        if S.Joined[pn] then return "start" end
        S.Joined[pn] = true
        return "join"
    end
    if button == "UpLeft" or button == "UpRight" or button == "DownLeft" or button == "DownRight" then
        if Advance(S, pn, button, now) then return "options" end
    end
    return nil
end

return Title
