-- hexagono-coop: the noteskin the theme switches to on co-op charts, so each player's
-- notes have their own color, as in Phoenix (P1 red, P2 blue, P3 yellow, P4 green,
-- P5 pink). Its metrics.ini says NumPlayers=5, so OutFox asks it for the notes of
-- players 2-5 as "P2 Tap Note", "P3 Hold Body Active"... (the same way as OutFox's own
-- co-op noteskin). pi/assets/coop_noteskin.py builds the folder from XSanity's SanityP1-5:
-- SanityP1 as it is (player 1, receptors, explosions) and the note art of SanityP<n>
-- renamed "<Button> P<n> <element>". The rest follows SanityP's NoteSkin.lua.
local Skin = {}

Skin.Colors = 5

-- elements drawn by another one, as in SanityP
Skin.Redirs = {
    ["Hold Head Active"] = "Tap Note",
    ["Hold Head Inactive"] = "Tap Note",
    ["Roll Head Active"] = "Tap Note",
    ["Roll Head Inactive"] = "Tap Note",
    ["Tap Fake"] = "Tap Note",
    ["Tap Lift"] = "Tap Note",
    ["Hold Topcap Inactive"] = "Hold Topcap Active",
    ["Hold Tail Inactive"] = "Hold Tail Active",
    ["Roll Topcap Active"] = "Hold Topcap Active",
    ["Roll Tail Active"] = "Hold Tail Active",
    ["Roll Topcap Inactive"] = "Hold Topcap Active",
    ["Roll Tail Inactive"] = "Hold Tail Active",
}
Skin.Blanks = { ["Hold Tail Active"] = true, ["Roll Tail Inactive"] = true }
-- elements that load from the UpLeft art whatever the column
Skin.Shared = { ["Explosion"] = true, ["Tap Mine"] = true, ["Receptor"] = true }
-- the art each player has (lower case: the engine writes "Bottomcap", the files "BottomCap")
Skin.PerPlayer = {
    ["tap note"] = true,
    ["hold body active"] = true, ["hold body inactive"] = true,
    ["hold bottomcap active"] = true, ["hold bottomcap inactive"] = true,
    ["roll body active"] = true, ["roll body inactive"] = true,
    ["roll bottomcap active"] = true, ["roll bottomcap inactive"] = true,
}

-- Button and element to load for the engine's request; element nil = blank. The third
-- value is "lift" for lifts, which pulse.
function Skin.Resolve(Button, Element, IsItem)
    local N, Base = string.match(Element, "^P(%d+) (.+)$")
    local Prefix = ""
    if N then
        local Color = (tonumber(N) - 1) % Skin.Colors + 1
        if Color > 1 then Prefix = "P" .. Color .. " " end
    else
        Base = Element
    end
    if Skin.Blanks[Base] then return Button, nil end
    local Target = Skin.Redirs[Base] or Base
    if Skin.Shared[Base] or IsItem then Button = "UpLeft" end
    if Skin.PerPlayer[string.lower(Target)] then Target = Prefix .. Target end
    return Button, Target, Base == "Tap Lift" and "lift" or nil
end

function Skin.Load()
    local Button, Element, Kind = Skin.Resolve(Var "Button", Var "Element", Var "IsItem")
    if not Element then
        if Var "SpriteOnly" then return LoadActor(NOTESKIN:GetPath("", "_blank")) end
        return Def.Actor {}
    end
    local t = LoadActor(NOTESKIN:GetPath(Button, Element))
    if Kind == "lift" then
        t.InitCommand = function(self) self:pulse():effectclock("beat"):effectmagnitude(1, 0.75, 0) end
    end
    return t
end
Skin.CommonLoad = Skin.Load

return Skin
