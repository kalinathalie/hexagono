-- Gameplay.ReceptorColumns: which receptor a pad press lights.

local Columns = LoadModule("Gameplay.ReceptorColumns.lua")
local P1, P2 = "PlayerNumber_P1", "PlayerNumber_P2"
local C1, C2 = "GameController_1", "GameController_2"

Test("Single: own pad only, columns 1-5", function()
    CheckEq(Columns.For("DownLeft", C1, P1, P1, "single"), 1, "down-left")
    CheckEq(Columns.For("DownRight", C1, P1, P1, "single"), 5, "down-right")
    CheckEq(Columns.For("Center", C2, P2, P1, "single"), nil, "the other player's pad")
    CheckEq(Columns.For("Center", C2, P2, P2, "single"), 3, "player 2 on pad 2")
    CheckEq(Columns.For("Start", C1, P1, P1, "single"), nil, "not a panel")
end)

Test("Double: the second pad is columns 6-10, told apart by the controller", function()
    -- in double the engine maps both pads to the playing player
    CheckEq(Columns.For("UpRight", C1, P1, P1, "double"), 4, "pad 1 up-right")
    CheckEq(Columns.For("UpRight", C2, P1, P1, "double"), 9, "pad 2 up-right lights the right side")
    CheckEq(Columns.For("DownLeft", C2, P1, P1, "double"), 6, "pad 2 down-left")
    -- player 2 playing double: pad 2 is theirs, pad 1 is the left side
    CheckEq(Columns.For("DownLeft", C1, P2, P2, "double"), 1, "P2 double: pad 1 is the left side")
    CheckEq(Columns.For("DownLeft", C2, P2, P2, "double"), 6, "P2 double: pad 2 is the right side")
end)

Test("Half-double: the inner six panels, by pad", function()
    CheckEq(Columns.For("UpRight", C1, P1, P1, "half"), 2, "pad 1 up-right")
    CheckEq(Columns.For("DownLeft", C1, P1, P1, "half"), nil, "pad 1 down-left is not used")
    CheckEq(Columns.For("UpLeft", C2, P1, P1, "half"), 5, "pad 2 up-left")
    CheckEq(Columns.For("Center", C2, P1, P1, "half"), 6, "pad 2 center")
    CheckEq(Columns.For("DownRight", C2, P1, P1, "half"), nil, "pad 2 down-right is not used")
end)

Test("Without a controller the player number decides the pad, as before", function()
    CheckEq(Columns.For("UpRight", nil, P2, P1, "double"), 9, "pad of the other player")
    CheckEq(Columns.For("UpRight", nil, P1, P1, "double"), 4, "own pad")
end)
