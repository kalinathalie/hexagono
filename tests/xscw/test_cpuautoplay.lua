-- Gameplay.CpuAutoPlay: the operator option that lets the engine's CPU play every song,
-- for viewing only.

Test("CpuAutoPlay.Controller gives the engine's AutoPlay value for the option", function()
    local C = LoadModule("Gameplay.CpuAutoPlay.lua")
    CheckEq(C.Controller(true), "PlayerController_Cpu", "on: the CPU plays")
    CheckEq(C.Controller(false), "PlayerController_Human", "off: back to human")
    CheckEq(C.Controller(nil), "PlayerController_Human", "unset: human")
end)

Test("CpuAutoPlay.SaveScore never saves a CPU play or a broken one", function()
    local C = LoadModule("Gameplay.CpuAutoPlay.lua")
    CheckEq(C.SaveScore(false, false), true, "human, not broken: saved")
    CheckEq(C.SaveScore(true, false), false, "CPU: never saved")
    CheckEq(C.SaveScore(false, true), false, "broken: not saved")
    CheckEq(C.SaveScore(true, true), false, "CPU and broken: not saved")
    CheckEq(C.SaveScore(nil, false), true, "option unset: saved")
end)
