-- Co-op script of the noteskin "<Base>-coop" (pi/assets/coop_noteskins.py writes the line
-- above, naming the player's own noteskin). Its metrics say NumPlayers=5, so OutFox asks
-- it for player n's notes as "P<n> Tap Note", "P<n> Hold Body Active"... and for player 1's
-- as the plain names. Each player's notes come from "<Base>-coop<n>", a copy of the
-- noteskin in that player's color (P1 red, P2 blue, P3 yellow, P4 green, P5 pink; from the
-- 6th on the colors repeat); receptors, explosions, mines and the rest from the noteskin
-- itself.
local Skin = {}

Skin.Base = Base
Skin.Colors = 5

-- the elements that are notes (lower case)
local NoteParts = { "^tap note", "^tap fake", "^tap lift", "^tap addition", "^hold ", "^roll " }
function Skin.IsNote(Element)
    local Lower = string.lower(Element)
    for _, Pattern in ipairs(NoteParts) do
        if string.find(Lower, Pattern) then return true end
    end
    return false
end

-- (noteskin, element) to load for the engine's request
function Skin.Resolve(Element)
    local N, Rest = string.match(Element, "^P(%d+) (.+)$")
    local Player = tonumber(N) or 1
    Rest = Rest or Element
    if not Skin.IsNote(Rest) then return Skin.Base, Rest end
    return Skin.Base .. "-coop" .. ((Player - 1) % Skin.Colors + 1), Rest
end

function Skin.Load()
    local Target, Element = Skin.Resolve(Var "Element")
    local t = NOTESKIN:LoadActorForNoteSkin(Var "Button", Element, Target)
    -- the engine wants a sprite here (hold parts); a noteskin that draws nothing for it
    -- answers with a plain actor, so a blank sprite takes its place
    if Var "SpriteOnly" and (type(t) ~= "table" or t.Class ~= "Sprite") then
        return LoadActor(NOTESKIN:GetPath("", "_blank"))
    end
    return t
end
Skin.CommonLoad = Skin.Load

return Skin
