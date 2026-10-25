-- Gameplay.JudgeOffset: the Judge Timing offset of the command window in the Lua timing.

local JudgeOffset = LoadModule("Gameplay.JudgeOffset.lua")
local P1, P2 = "PlayerNumber_P1", "PlayerNumber_P2"

Test("JudgeOffset.Seconds reads the preference in ms", function()
    CheckEq(JudgeOffset.Seconds(nil), 0, "unset")
    CheckEq(JudgeOffset.Seconds(20), 0.02, "20 ms")
    CheckEq(JudgeOffset.Seconds("-15"), -0.015, "string from the prefs file")
    CheckEq(JudgeOffset.Seconds("junk"), 0, "not a number")
end)

Test("JudgeOffset.Shift: a positive offset judges later", function()
    -- the engine's Window is negative for late presses
    CheckEq(JudgeOffset.Shift(-0.03, 0.03), 0, "30 ms late with +30 ms is on time")
    CheckEq(JudgeOffset.Shift(0.02, 0.03), 0.05, "an early press gets earlier")
    CheckEq(JudgeOffset.Shift(0.01, 0), 0.01, "no offset")
end)

Test("JudgeOffset.For picks the offset of the player who stepped", function()
    local Offsets = { [P1] = 0.02, [P2] = -0.01 }
    CheckEq(JudgeOffset.For(Offsets, P2, { P1, P2 }), -0.01, "by player")
    CheckEq(JudgeOffset.For(Offsets, nil, { P1 }), 0.02, "message without a player, one player")
    CheckEq(JudgeOffset.For(Offsets, nil, { P1, P2 }), 0, "message without a player, two players")
    CheckEq(JudgeOffset.For({}, P1, { P1 }), 0, "no offset saved")
end)
