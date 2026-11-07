-- Select.Hud: the top HUD logic. The level shown on the player card (1 to 10000) and
-- its rank color, gray at level 1 up to a rainbow at the maximum; the timer text.

Test("Level grows with the square root of the dance points, from 1", function()
    local L = LoadModule("Select.Hud.lua")
    CheckEq(L.Level(0), 1, "no points: level 1")
    CheckEq(L.Level(499), 1, "just under the first step")
    CheckEq(L.Level(500), 2, "500 points: level 2")
    CheckEq(L.Level(2000), 3, "2000 points: level 3")
    CheckEq(L.Level(500 * 98 * 98), 99, "level 99")
end)

Test("Level is 1 for missing or bad points", function()
    local L = LoadModule("Select.Hud.lua")
    CheckEq(L.Level(nil), 1, "nil")
    CheckEq(L.Level(-500), 1, "negative")
    CheckEq(L.Level(0 / 0), 1, "NaN")
end)

Test("Level stops at 10000", function()
    local L = LoadModule("Select.Hud.lua")
    CheckEq(L.MAX, 10000, "the maximum")
    CheckEq(L.Level(500 * 9998 * 9998), 9999, "one below the maximum")
    CheckEq(L.Level(500 * 9999 * 9999), 10000, "the maximum")
    CheckEq(L.Level(1e15), 10000, "far above: still the maximum")
    CheckEq(L.Level(1 / 0), 10000, "infinite points: the maximum")
end)

Test("Tier follows the usual game ranks, from Iron at 1 to Radiant at 10000", function()
    local L = LoadModule("Select.Hud.lua")
    local Want = {
        { 1, "Iron" }, { 9, "Iron" }, { 10, "Bronze" }, { 24, "Bronze" }, { 25, "Silver" },
        { 50, "Gold" }, { 100, "Platinum" }, { 250, "Emerald" }, { 500, "Diamond" },
        { 1000, "Master" }, { 2500, "Grandmaster" }, { 5000, "Challenger" }, { 9999, "Challenger" },
        { 10000, "Radiant" },
    }
    for _, W in ipairs(Want) do CheckEq(L.Tier(W[1]).Name, W[2], "level " .. W[1]) end
    CheckEq(L.Tier(0).Name, "Iron", "below 1: the first tier")
    CheckEq(L.Tier(20000).Name, "Radiant", "above the maximum: the last tier")
end)

Test("Tiers start at increasing levels and each one has its own color", function()
    local L = LoadModule("Select.Hud.lua")
    CheckEq(L.TIERS[1].From, 1, "the first tier starts at level 1")
    CheckEq(L.TIERS[#L.TIERS].From, L.MAX, "the last tier is the maximum alone")
    for i = 2, #L.TIERS do
        Check(L.TIERS[i].From > L.TIERS[i - 1].From, "tier " .. i .. " starts after tier " .. (i - 1))
        Check(L.TIERS[i].Color ~= L.TIERS[i - 1].Color, "tier " .. i .. " color differs from the one before")
    end
end)

Test("Color is an engine color: four numbers from 0 to 1, opaque", function()
    local L = LoadModule("Select.Hud.lua")
    for _, Level in ipairs({ 1, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000 }) do
        local C = L.Color(Level)
        CheckEq(#C, 4, "level " .. Level .. ": four components")
        for k = 1, 4 do Check(C[k] >= 0 and C[k] <= 1, "level " .. Level .. " component " .. k .. " in 0..1") end
        CheckEq(C[4], 1, "level " .. Level .. ": opaque")
    end
end)

Test("Color starts gray and ends vivid", function()
    local L = LoadModule("Select.Hud.lua")
    local function Saturation(C) return math.max(C[1], C[2], C[3]) - math.min(C[1], C[2], C[3]) end
    Check(Saturation(L.Color(1)) < 0.08, "level 1 is gray")
    Check(Saturation(L.Color(5000)) > 0.6, "Challenger is vivid")
    Check(Saturation(L.Color(10000)) > 0.6, "the maximum is vivid")
    local C = L.Color(1)
    Check(C[1] > 0.5, "level 1 gray is light enough to read on the silver bar")
end)

Test("Rainbow only at the maximum", function()
    local L = LoadModule("Select.Hud.lua")
    CheckEq(L.Rainbow(9999), false, "9999")
    CheckEq(L.Rainbow(10000), true, "10000")
    CheckEq(L.Rainbow(1), false, "1")
end)

Test("TimerText shows whole seconds rounded up, from 0 to 99", function()
    local L = LoadModule("Select.Hud.lua")
    CheckEq(L.TimerText(99), "99", "99")
    CheckEq(L.TimerText(150), "99", "above 99: 99")
    CheckEq(L.TimerText(9.2), "10", "rounded up")
    CheckEq(L.TimerText(9), "9", "one digit")
    CheckEq(L.TimerText(0), "0", "zero")
    CheckEq(L.TimerText(-0.5), "0", "negative: zero, never -0")
    CheckEq(L.TimerText(nil), "99", "no timer: 99")
end)
