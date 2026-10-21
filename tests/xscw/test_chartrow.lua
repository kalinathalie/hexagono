-- Select.ChartRow: the single row of difficulty bubbles (slots, scrolling, colors).

local Row = LoadModule("Select.ChartRow.lua")
local function C(t, m, d) return { Type = t, Meter = m, Description = d or "" } end

Test("ChartRow.MeterText pads to two digits and marks 99", function()
    CheckEq(Row.MeterText(5), "05", "05"); CheckEq(Row.MeterText(17), "17", "17"); CheckEq(Row.MeterText(99), "??", "99")
end)

Test("ChartRow.Kind colors plain singles red and plain doubles green; SP, DP, co-op and half-double keep the theme colors", function()
    CheckEq(Row.Kind(C("Single", 17)), "single", "S"); CheckEq(Row.Kind(C("Single", 17, "SP")), "other", "SP")
    CheckEq(Row.Kind(C("Double", 22)), "double", "D"); CheckEq(Row.Kind(C("Double", 99, "COOP x2")), "other", "coop")
    CheckEq(Row.Kind(C("Double", 20, "DP")), "other", "DP"); CheckEq(Row.Kind(C("Halfdouble", 12)), "other", "HD")
    CheckEq(Row.Kind(C("Single", 10, "S10 NEW")), "single", "label without SP")
end)

Test("ChartRow.MainIndex follows the enabled player who moved last, so the cursor stays visible", function()
    local Index = { P1 = 3, P2 = 14 }
    CheckEq(Row.MainIndex(Index, { P1 = true, P2 = false }, nil), 3, "P2 not playing is ignored")
    CheckEq(Row.MainIndex(Index, { P1 = true, P2 = true }, "P1"), 3, "last mover P1")
    CheckEq(Row.MainIndex(Index, { P1 = true, P2 = true }, "P2"), 14, "last mover P2")
    CheckEq(Row.MainIndex(Index, { P1 = true, P2 = true }, nil), 14, "no mover: the farthest, as before")
    CheckEq(Row.MainIndex(Index, { P1 = false, P2 = false }, nil), 1, "nobody enabled")
    local S = Row.Slots({ C("Single",1), C("Single",2), C("Single",3), C("Single",4), C("Single",5), C("Single",6), C("Single",7),
        C("Double",8), C("Double",9), C("Double",10), C("Double",11), C("Double",12), C("Double",13), C("Double",14) }, 3, 10)
    CheckEq(S.Items[3].Index, 3, "P1 cursor visible in slot 3")
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
