-- Pad.Code: a sequence of pad panels entered by one player. Pure Lua.
--
--   New(sequence, gap) -> code   (gap: most seconds allowed between two panels)
--   Press(code, pn, button, now) -> true when the player just completed it
-- Each player has their own progress. A wrong panel restarts it (counting as the
-- first step when it is the first panel of the sequence); a pause longer than
-- gap restarts it too.

local Code = {}

function Code.New(sequence, gap)
    return { Seq = sequence, Gap = gap or 2, Step = {}, Last = {} }
end

function Code.Press(C, pn, button, now)
    local Step = C.Step[pn] or 0
    if Step > 0 and C.Last[pn] and now - C.Last[pn] > C.Gap then Step = 0 end
    if C.Seq[Step + 1] == button then
        Step = Step + 1
    else
        Step = (C.Seq[1] == button) and 1 or 0
    end
    C.Last[pn] = now
    if Step == #C.Seq then
        C.Step[pn] = 0
        return true
    end
    C.Step[pn] = Step
    return false
end

return Code
