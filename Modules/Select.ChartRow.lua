-- Select.ChartRow: model of the single row of difficulty bubbles at the bottom
-- of the song select screen. Pure Lua, no engine calls.
--
-- Charts are tables { Type = "Single"|"Halfdouble"|"Double"|..., Meter = number,
-- Description = string }, already filtered and sorted by ChartDisplay.
--
--   Slots(Charts, MainIndex, Visible) -> { Offset, Items = { [1..Visible] = { Chart, Index } }, MoreLeft, MoreRight }
--   MeterText(Meter) -> "05" | "17" | "??" (99 = unrated)
--   Kind(Chart) -> "single" | "double" | "other"   (bubble color family)

local Row = {}

function Row.MeterText(Meter)
    if Meter == 99 then return "??" end
    return string.format("%02d", Meter)
end

function Row.Kind(Chart)
    local Type = tostring(Chart.Type)
    if Type == "Single" then return "single" end
    if Type == "Double" then return "double" end
    return "other"
end

-- Same scrolling rule as the previous ChartDisplay: the list only scrolls once the
-- cursor would leave the visible slots; the last chart stays flush right.
function Row.Slots(Charts, MainIndex, Visible)
    local Count = #Charts
    local Offset = 0
    if MainIndex + 1 > Visible then
        Offset = MainIndex - Visible + (MainIndex == Count and 0 or 1)
    end
    if Offset + Visible > Count then Offset = math.max(0, Count - Visible) end

    local Items = {}
    for i = 1, Visible do
        local Index = Offset + i
        Items[i] = { Chart = Charts[Index], Index = Charts[Index] and Index or nil }
    end
    return {
        Offset = Offset,
        Items = Items,
        MoreLeft = Offset > 0,
        MoreRight = Offset + Visible < Count,
    }
end

return Row
