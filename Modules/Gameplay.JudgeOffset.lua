-- Gameplay.JudgeOffset: the Judge Timing offset of the command window (JudgeOffset
-- preference, ms per player) as Options.SmartTiming applies it. Pure Lua.
--
--   Seconds(value) -> offset in seconds from the preference value, 0 when unset
--   Shift(window, seconds) -> the press offset as the judgment sees it; the engine's
--       window is negative for late presses and a positive offset judges later
--   For(offsets, player, humans) -> offset for one judgment: the stepping player's,
--       or the only human player's when the message doesn't say whose step it was

local JudgeOffset = {}

function JudgeOffset.Seconds(Value)
    return (tonumber(Value) or 0) / 1000
end

function JudgeOffset.Shift(Window, Seconds)
    return Window + Seconds
end

function JudgeOffset.For(Offsets, Player, Humans)
    if Player then return Offsets[Player] or 0 end
    if #Humans == 1 then return Offsets[Humans[1]] or 0 end
    return 0
end

return JudgeOffset
