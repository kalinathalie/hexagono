-- Gameplay.Coop: co-op charts (Phoenix CO-OP; in the simfiles, notes X/Y/Z... per player)
-- are played on the co-op version of the player's own noteskin, "<noteskin>-coop", which
-- draws each player's notes in their own color (built by pi/assets/coop_noteskins.py with
-- the script pi/config/noteskins/coop/NoteSkin.lua).
--
--   IsCoop(players, desc)      the engine counts more than one player for the chart
--                              (Steps:GetNumCoOpPlayers), or the description says COOP
--   SkinFor(noteskin)          the co-op version's name
--   IsGenerated(noteskin)      a co-op version or one of its color copies ("-coop", "-coop1"..)
--   Choosable(names) -> names  the noteskin list without them
local C = {}

function C.IsCoop(Players, Description)
    if type(Players) == "number" and Players > 1 then return true end
    return string.find(string.upper(tostring(Description or "")), "COOP", 1, true) ~= nil
end

function C.IsGenerated(Name)
    local Lower = string.lower(tostring(Name))
    return Lower == "hexagono-coop" or string.find(Lower, "%-coop%d?$") ~= nil
end

function C.SkinFor(Name)
    if Name == nil then return nil end
    if string.find(string.lower(Name), "%-coop$") then return Name end
    return Name .. "-coop"
end

function C.Choosable(Names)
    local Out = {}
    for _, Name in ipairs(Names or {}) do
        if not C.IsGenerated(Name) then Out[#Out + 1] = Name end
    end
    return Out
end

return C
