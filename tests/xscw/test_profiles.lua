-- Profile.Slots (reserved empty profiles used to create profiles from the pad)
-- and Profile.Keyboard (name entry with the pad).

local Slots = LoadModule("Profile.Slots.lua")
local Keyboard = LoadModule("Profile.Keyboard.lua")

local function Profiles(names)
    local t = {}
    for i, n in ipairs(names) do t[i] = { Index = i - 1, Name = n } end
    return t
end

Test("Slots: reserved profiles are hidden; the list is Guest, the real profiles, then Create", function()
    local L = Slots.VisibleList(Profiles({ "K4L1zinha", Slots.MARKER, "hexagono", Slots.MARKER }))
    CheckEq(#L, 4, "count")
    CheckEq(L[1].Kind, "guest", "guest first"); CheckEq(L[1].Engine, 0, "guest is engine index 0")
    CheckEq(L[2].Engine, 1, "K4L1zinha is engine index 1"); CheckEq(L[2].Name, "K4L1zinha", "name")
    CheckEq(L[3].Engine, 3, "hexagono skips the reserved profile"); CheckEq(L[4].Kind, "create", "create last")
end)

Test("Slots: FirstFree gives the first reserved profile not taken this session", function()
    local P = Profiles({ "K4L1zinha", Slots.MARKER, "hexagono", Slots.MARKER })
    CheckEq(Slots.FirstFree(P, {}), 1, "local index of the first reserved")
    CheckEq(Slots.FirstFree(P, { [1] = true }), 3, "skips one already used")
    CheckEq(Slots.FirstFree(P, { [1] = true, [3] = true }), nil, "none left")
end)

Test("Slots: NextId is the lowest free 8-digit id", function()
    CheckEq(Slots.NextId({ "00000000", "00000001", "00000003" }), "00000002", "gap")
    CheckEq(Slots.NextId({}), "00000000", "empty")
    CheckEq(Slots.NextId({ "00000000", "00000001" }), "00000002", "after the last")
end)

Test("Slots: Files builds Editable.ini, Stats.xml and Type.ini for a reserved profile", function()
    local F = Slots.Files("0123456789abcdef", 105)
    Check(F["Editable.ini"]:find("DisplayName=" .. Slots.MARKER, 1, true) ~= nil, "editable name")
    Check(F["Stats.xml"]:find("<DisplayName>" .. Slots.MARKER .. "</DisplayName>", 1, true) ~= nil, "stats name")
    Check(F["Stats.xml"]:find("<Guid>0123456789abcdef</Guid>", 1, true) ~= nil, "guid")
    Check(F["Type.ini"]:find("Priority=105", 1, true) ~= nil, "priority")
end)

Test("Slots: CleanName trims, limits to 12 characters and refuses empty names", function()
    CheckEq(Slots.CleanName("  KALI  "), "KALI", "trim")
    CheckEq(Slots.CleanName("ABCDEFGHIJKLMNOP"), "ABCDEFGHIJKL", "12 max")
    CheckEq(Slots.CleanName("   "), nil, "only spaces")
    CheckEq(Slots.CleanName(Slots.MARKER), nil, "the marker itself")
end)

Test("Keyboard: starts on A; left from A wraps to OK, then DEL", function()
    local K = Keyboard.New()
    CheckEq(Keyboard.Current(K), "A", "starts on A")
    Keyboard.Move(K, -1); CheckEq(Keyboard.Current(K), "OK", "wraps to OK")
    Keyboard.Move(K, -1); CheckEq(Keyboard.Current(K), "DEL", "then DEL")
    Keyboard.Move(K, 2); CheckEq(Keyboard.Current(K), "A", "back to A")
end)

Test("Keyboard: center types the letter; the case key switches letters to lowercase", function()
    local K = Keyboard.New()
    CheckEq(Keyboard.Press(K), "typed", "type A"); CheckEq(K.Name, "A", "name A")
    while Keyboard.Current(K) ~= "Aa" do Keyboard.Move(K, 1) end
    CheckEq(Keyboard.Press(K), "case", "toggle case")
    while Keyboard.Current(K) ~= "b" do Keyboard.Move(K, 1) end
    Keyboard.Press(K); CheckEq(K.Name, "Ab", "lowercase b")
    CheckEq(Keyboard.Label(K, "SPACE"), " ", "space types a space")
end)

Test("Keyboard: DEL and the upper panels erase; erasing an empty name cancels", function()
    local K = Keyboard.New()
    Keyboard.Press(K); Keyboard.Press(K)
    CheckEq(Keyboard.Erase(K), "erased", "erase"); CheckEq(K.Name, "A", "one left")
    while Keyboard.Current(K) ~= "DEL" do Keyboard.Move(K, 1) end
    CheckEq(Keyboard.Press(K), "erased", "DEL key"); CheckEq(K.Name, "", "empty")
    CheckEq(Keyboard.Erase(K), "cancel", "cancel when empty")
end)

Test("Keyboard: OK needs a name; typing stops at 12 characters", function()
    local K = Keyboard.New()
    while Keyboard.Current(K) ~= "OK" do Keyboard.Move(K, 1) end
    CheckEq(Keyboard.Press(K), "empty", "OK on an empty name")
    local K2 = Keyboard.New()
    for i = 1, 12 do Keyboard.Press(K2) end
    CheckEq(Keyboard.Press(K2), "full", "13th letter refused"); CheckEq(#K2.Name, 12, "12 letters")
    while Keyboard.Current(K2) ~= "OK" do Keyboard.Move(K2, 1) end
    CheckEq(Keyboard.Press(K2), "ok", "OK with a name")
end)
