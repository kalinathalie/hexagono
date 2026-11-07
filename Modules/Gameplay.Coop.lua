-- Gameplay.Coop: co-op charts (Phoenix CO-OP; in the simfiles, notes X/Y/Z... per player)
-- are played with the hexagono-coop noteskin, which draws each player's notes in their
-- own color (pi/config/noteskins/hexagono-coop, built by pi/assets/coop_noteskin.py).
--
--   SKIN, BASE                 the co-op noteskin and the one it needs (XSanity's SanityP1)
--   IsCoop(players, desc)      the engine counts more than one player for the chart
--                              (Steps:GetNumCoOpPlayers), or the description says COOP
--   Choosable(names) -> names  the noteskin list without the co-op noteskin
local C = {}

C.SKIN = "hexagono-coop"
C.BASE = "SanityP1"

function C.IsCoop(Players, Description)
    if type(Players) == "number" and Players > 1 then return true end
    return string.find(string.upper(tostring(Description or "")), "COOP", 1, true) ~= nil
end

function C.Choosable(Names)
    local Out = {}
    for _, Name in ipairs(Names or {}) do
        if string.lower(tostring(Name)) ~= C.SKIN then Out[#Out + 1] = Name end
    end
    return Out
end

return C
