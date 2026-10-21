-- Select.Wheel: geometry of the jacket wheel, position counter, image choice,
-- and which slots are shown when a list is shorter than the wheel.

local Wheel = LoadModule("Select.Wheel.lua")

Test("Wheel.Counter pads position and total", function()
    CheckEq(Wheel.Counter(36, 139), "036/139", "pad"); CheckEq(Wheel.Counter(7, 9), "007/009", "small")
end)

Test("Wheel.Position: center item full size, the others 80% with Phoenix spacing", function()
    local x, z = Wheel.Position(0)
    CheckEq(x, 0, "center x"); CheckEq(z, 1, "center zoom")
    x, z = Wheel.Position(1); CheckEq(x, 222, "right neighbor"); CheckEq(z, 0.8, "neighbor zoom")
    x = Wheel.Position(-1); CheckEq(x, -222, "left neighbor")
    x = Wheel.Position(2); CheckEq(x, 427, "second")
    x = Wheel.Position(-3); CheckEq(x, -632, "third, half off-screen")
    x = Wheel.Position(4); CheckEq(x, 837, "hidden slot")
end)

Test("Wheel.SlotVisible hides repeated items when the list is shorter than the wheel", function()
    CheckEq(Wheel.SlotVisible(0, 1), true, "one song: center only")
    CheckEq(Wheel.SlotVisible(1, 1), false, "one song: no right")
    CheckEq(Wheel.SlotVisible(-1, 1), false, "one song: no left")
    CheckEq(Wheel.SlotVisible(1, 2), true, "two songs: right")
    CheckEq(Wheel.SlotVisible(-1, 2), false, "two songs: no left")
    CheckEq(Wheel.SlotVisible(-1, 3), true, "three: left"); CheckEq(Wheel.SlotVisible(2, 3), false, "three: no +2")
    CheckEq(Wheel.SlotVisible(2, 4), true, "four: +2"); CheckEq(Wheel.SlotVisible(-2, 4), false, "four: no -2")
    CheckEq(Wheel.SlotVisible(-4, 9), true, "full list"); CheckEq(Wheel.SlotVisible(4, 140), true, "long list")
end)

Test("Wheel.ImageKind prefers jacket, then banner, then nothing", function()
    CheckEq(Wheel.ImageKind(true, true), "jacket", "j"); CheckEq(Wheel.ImageKind(false, true), "banner", "b"); CheckEq(Wheel.ImageKind(false, false), "none", "n")
end)
