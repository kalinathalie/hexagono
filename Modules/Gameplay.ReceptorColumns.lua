-- Gameplay.ReceptorColumns: the column a pad press belongs to, for the receptor glow.
-- Pure Lua.
--
--   For(button, controller, eventPlayer, pn, kind) -> column or nil
--     button      pad panel ("DownLeft", "UpLeft", "Center", "UpRight", "DownRight")
--     controller  which pad was pressed: OutFox sends "GameController_Left" /
--                 "GameController_Right" (its Lua docs say "GameController_1" / "_2")
--     eventPlayer the player the engine gave the press to
--     pn          the player whose glow this is
--     kind        "single" | "double" | "half"
--
-- In double and half-double the engine gives both pads to the playing player, so
-- the pad is told by the controller: the left half of the field is controller 1,
-- whoever plays. The right pad is columns 6-10 in double; half-double uses the inner
-- six panels (UpRight, Center, DownRight of the left pad, then DownLeft, UpLeft,
-- Center of the right one).

local Columns = {}

local BY_BUTTON = { DownLeft = 1, UpLeft = 2, Center = 3, UpRight = 4, DownRight = 5 }
local HALF_LEFT = { [3] = 1, [4] = 2, [5] = 3 }
local HALF_RIGHT = { [1] = 4, [2] = 5, [3] = 6 }
local LEFT_PAD = { GameController_Left = true, GameController_1 = true }

function Columns.For(button, controller, eventPlayer, pn, kind)
    local Index = BY_BUTTON[button]
    if not Index then return nil end
    if kind == "single" then
        return eventPlayer == pn and Index or nil
    end
    local Left
    if controller then
        Left = LEFT_PAD[controller] == true
    else
        Left = eventPlayer == pn   -- no controller given: the player decides, as before
    end
    if kind == "half" then
        return (Left and HALF_LEFT or HALF_RIGHT)[Index]
    end
    return Left and Index or (Index + 5)
end

return Columns
