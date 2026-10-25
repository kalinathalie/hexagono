-- Title.Input: join and start with the center panel, Options secret code.

local Title = LoadModule("Title.Input.lua")
local P1, P2 = "PlayerNumber_P1", "PlayerNumber_P2"

local function Code(S, pn, t0)
    local Seq = { "UpLeft", "UpRight", "DownLeft", "DownRight", "UpLeft", "UpRight", "DownLeft", "DownRight" }
    local Last
    for i, b in ipairs(Seq) do Last = Title.Press(S, pn, b, t0 + i * 0.3) end
    return Last
end

Test("Title: first center press joins, second press by a joined player starts", function()
    local S = Title.New()
    CheckEq(Title.Press(S, P1, "Center", 0), "join", "P1 joins")
    CheckEq(Title.Press(S, P1, "Center", 1), "start", "P1 starts")
end)

Test("Title: the other player can join before the game starts, then either one starts", function()
    local S = Title.New()
    Title.Press(S, P1, "Center", 0)
    CheckEq(Title.Press(S, P2, "Center", 1), "join", "P2 joins")
    CheckEq(Title.Press(S, P2, "Center", 2), "start", "P2 starts")
    local S2 = Title.New()
    Title.Press(S2, P2, "Center", 0); Title.Press(S2, P1, "Center", 0.5)
    CheckEq(Title.Press(S2, P1, "Center", 1), "start", "P1 starts after both joined")
end)

Test("Title: the Start key counts as the center panel", function()
    local S = Title.New()
    CheckEq(Title.Press(S, P1, "Start", 0), "join", "start key joins")
    CheckEq(Title.Press(S, P1, "MenuStart", 1), "start", "menu start starts")
end)

Test("Title: red left, red right, blue left, blue right twice opens Options", function()
    CheckEq(Code(Title.New(), P1, 0), "options", "P1 code")
    CheckEq(Code(Title.New(), P2, 0), "options", "P2 code")
end)

Test("Title: the code fails on a wrong panel, a center press or a long pause", function()
    local S = Title.New()
    Title.Press(S, P1, "UpLeft", 0); Title.Press(S, P1, "UpRight", 0.2); Title.Press(S, P1, "UpRight", 0.4)
    CheckEq(Code(S, P1, 1), "options", "a wrong panel only restarts the code")
    local S2 = Title.New()
    local Seq = { "UpLeft", "UpRight", "DownLeft", "DownRight", "UpLeft", "UpRight", "DownLeft", "DownRight" }
    local Got
    for i, b in ipairs(Seq) do Got = Title.Press(S2, P1, b, i * (i == 5 and 3 or 0.3)) end
    CheckEq(Got, nil, "pause over 2 s between panels breaks the code")
    local S3 = Title.New()
    for i = 1, 4 do Title.Press(S3, P1, Seq[i], i * 0.3) end
    Title.Press(S3, P1, "Center", 1.5)
    local Last
    for i = 5, 8 do Last = Title.Press(S3, P1, Seq[i], 1.5 + i * 0.3) end
    CheckEq(Last, nil, "a center press in the middle breaks the code")
end)

Test("Title: each player has their own code progress", function()
    local S = Title.New()
    local Seq = { "UpLeft", "UpRight", "DownLeft", "DownRight", "UpLeft", "UpRight", "DownLeft", "DownRight" }
    local Last
    for i, b in ipairs(Seq) do
        Last = Title.Press(S, P1, b, i * 0.3)
        if i < 8 then Title.Press(S, P2, "UpLeft", i * 0.3 + 0.1) end
    end
    CheckEq(Last, "options", "P2 presses do not break P1's code")
end)

Test("Title: other buttons do nothing", function()
    local S = Title.New()
    CheckEq(Title.Press(S, P1, "UpLeft", 0), nil, "single red panel")
    CheckEq(Title.Press(S, P1, "MenuLeft", 0.1), nil, "menu left")
end)
