-- Select.ChartRow: the single row of difficulty bubbles (slots, scrolling, colors).

local Row = LoadModule("Select.ChartRow.lua")
local function C(t, m, d) return { Type = t, Meter = m, Description = d or "" } end

Test("ChartRow.MeterText pads to two digits and marks 99", function()
    CheckEq(Row.MeterText(5), "05", "05"); CheckEq(Row.MeterText(17), "17", "17"); CheckEq(Row.MeterText(99), "??", "99")
end)

Test("ChartRow.Kind colors singles red and doubles green", function()
    CheckEq(Row.Kind(C("Single", 17)), "single", "S"); CheckEq(Row.Kind(C("Single", 17, "SP")), "single", "SP")
    CheckEq(Row.Kind(C("Double", 22)), "double", "D"); CheckEq(Row.Kind(C("Double", 99, "COOP x2")), "double", "coop")
    CheckEq(Row.Kind(C("Halfdouble", 12)), "other", "HD")
end)

Test("ChartRow.Slots fills 10 slots and scrolls for 14 charts", function()
    local Charts = {}
    for i = 1, 14 do Charts[i] = C(i <= 8 and "Single" or "Double", i) end
    local S = Row.Slots(Charts, 1, 10)
    CheckEq(S.Offset, 0, "no offset"); CheckEq(S.Items[1].Index, 1, "first"); CheckEq(S.Items[10].Index, 10, "tenth")
    CheckEq(S.MoreLeft, false, "no left"); CheckEq(S.MoreRight, true, "right")
    S = Row.Slots(Charts, 12, 10)
    CheckEq(S.Offset, 3, "offset 3"); CheckEq(S.Items[9].Index, 12, "cursor visible"); CheckEq(S.MoreLeft, true, "left")
    S = Row.Slots(Charts, 14, 10)
    CheckEq(S.Offset, 4, "offset 4"); CheckEq(S.Items[10].Index, 14, "last visible"); CheckEq(S.MoreRight, false, "no right")
    S = Row.Slots({ C("Single", 3) }, 1, 10)
    CheckEq(S.Items[1].Index, 1, "one chart"); CheckEq(S.Items[2].Chart, nil, "empty slot"); CheckEq(#S.Items, 10, "always 10 slots")
end)
