-- Select.Hud: the logic of the top HUD of the select and result screens (SelectHud.lua).
--
--   Level(dancePoints)  the profile level on the player card: 1 + floor(sqrt(points / 500)),
--                       from 1 up to MAX (10000); 1 for missing or bad points
--   Tier(level)         the rank of that level, after the ranks most games use (Iron,
--                       Bronze, Silver, Gold, Platinum, Emerald, Diamond, Master,
--                       Grandmaster, Challenger), with Radiant for the maximum alone
--   Color(level)        the tier's color as an engine color {r, g, b, 1}: gray at level 1,
--                       ever more vivid up the ranks
--   Rainbow(level)      true at the maximum, drawn cycling through every color
--   TimerText(seconds)  the menu timer as Phoenix shows it: whole seconds rounded up,
--                       0 to 99 ("99" without a timer)
local H = {}

H.MAX = 10000

-- Each tier starts at a level about twice the one before, so the colors keep
-- changing as a player goes up, and the last one is the maximum alone
H.TIERS = {
    { From = 1, Name = "Iron", Color = "#9aa0a8" },
    { From = 10, Name = "Bronze", Color = "#e08c4a" },
    { From = 25, Name = "Silver", Color = "#e6edf5" },
    { From = 50, Name = "Gold", Color = "#ffd23a" },
    { From = 100, Name = "Platinum", Color = "#3fe6c8" },
    { From = 250, Name = "Emerald", Color = "#2cec6a" },
    { From = 500, Name = "Diamond", Color = "#4aa3ff" },
    { From = 1000, Name = "Master", Color = "#a855ff" },
    { From = 2500, Name = "Grandmaster", Color = "#ff2d4f" },
    { From = 5000, Name = "Challenger", Color = "#ff9d00" },
    { From = H.MAX, Name = "Radiant", Color = "#ff36e0" },
}

function H.Level(DancePoints)
    local P = tonumber(DancePoints)
    if not P or P ~= P or P < 0 then return 1 end
    return math.min(H.MAX, math.floor(math.sqrt(P / 500)) + 1)
end

function H.Tier(Level)
    for i = #H.TIERS, 1, -1 do
        if Level >= H.TIERS[i].From then return H.TIERS[i] end
    end
    return H.TIERS[1]
end

function H.Color(Level)
    local Hex = H.Tier(Level).Color
    local function Byte(i) return tonumber(Hex:sub(i, i + 1), 16) / 255 end
    return { Byte(2), Byte(4), Byte(6), 1 }
end

function H.Rainbow(Level)
    return Level >= H.MAX
end

function H.TimerText(Seconds)
    if Seconds == nil then return "99" end
    local S = math.min(99, math.ceil(Seconds))
    if S < 0 or S ~= S then S = 0 end
    return string.format("%d", S)
end

return H
