-- Select.Wheel: layout of the 7-item jacket wheel, position counter, image choice.

local Wheel = LoadModule("Select.Wheel.lua")

Test("Wheel.Counter pads position and total", function()
    CheckEq(Wheel.Counter(36, 139), "036/139", "pad"); CheckEq(Wheel.Counter(7, 9), "007/009", "small")
end)

Test("Wheel.Layout puts the selected item in the center and fades the edges", function()
    local L = Wheel.Layout(7, 640, 4)
    CheckEq(L[4].X, 640, "center x"); CheckEq(L[4].Zoom, 1, "center zoom"); CheckEq(L[4].Alpha, 1, "center alpha")
    CheckEq(L[3].X, 490, "left neighbor"); CheckEq(L[5].Zoom, 0.75, "neighbor zoom")
    CheckEq(L[1].X, 190, "left edge"); CheckEq(L[1].Alpha, 0.55, "edge alpha"); CheckEq(L[7].Zoom, 0.6, "edge zoom")
    CheckEq(L[1].Offset, -3, "offset left"); CheckEq(L[7].Offset, 3, "offset right")
end)

Test("Wheel.ImageKind prefers jacket, then banner, then nothing", function()
    CheckEq(Wheel.ImageKind(true, true), "jacket", "j"); CheckEq(Wheel.ImageKind(false, true), "banner", "b"); CheckEq(Wheel.ImageKind(false, false), "none", "n")
end)
