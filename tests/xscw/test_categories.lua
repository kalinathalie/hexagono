-- Tests for Modules/XSCW.Categories.lua (content and actions of the command window)

local BuildCategories = LoadModule("XSCW.Categories.lua")
local P1 = "PlayerNumber_P1"

-- In-memory stand-in for the engine/theme dependencies
local function FakeDeps(Overrides)
    local D = {
        AV = { [P1] = 200 },
        AVType = { [P1] = false },
        Mods = { [P1] = {} },
        Skin = { [P1] = "nx2" },
        NoteSkinNames = { "default", "nx2", "Infinity" },
        Prefs = { [P1] = {} },
    }
    function D.GetPref(pn, key) return D.Prefs[pn][key] end
    function D.SetPref(pn, key, value) D.Prefs[pn][key] = value end
    function D.GetAV(pn) return D.AV[pn] end
    function D.SetAV(pn, n) D.AV[pn] = n end
    function D.GetAVType(pn) return D.AVType[pn] end
    function D.SetAVType(pn, t) D.AVType[pn] = t end
    function D.GetMod(pn, name) return D.Mods[pn][name] == true end
    function D.SetMod(pn, name, on) D.Mods[pn][name] = on end
    function D.GetNoteSkin(pn) return D.Skin[pn] end
    function D.SetNoteSkin(pn, name) D.Skin[pn] = name end
    function D.Text(key) return key end
    for k, v in pairs(Overrides or {}) do D[k] = v end
    return D
end

Test("Four categories in order with their kinds", function()
    local C = BuildCategories(FakeDeps())
    CheckEq(#C, 4, "count")
    CheckEq(C[1].Name, "Speed", "1")
    CheckEq(C[2].Name, "AutoVelocity", "2")
    CheckEq(C[3].Name, "Display", "3")
    CheckEq(C[4].Name, "NoteSkin", "4")
    CheckEq(C[1].Kind, "items", "Speed kind")
    CheckEq(C[2].Kind, "items", "AV kind")
    CheckEq(C[3].Kind, "items", "Display kind")
    CheckEq(C[4].Kind, "noteskin", "NoteSkin kind")
    CheckEq(C[1].Title, "01_title", "Speed title")
    CheckEq(C[2].Title, "11_title", "AV title")
    CheckEq(C[3].Title, "02_title", "Display title")
    CheckEq(C[4].Title, "03_title", "NoteSkin title")
end)

Test("Display items: 8 badges from the Icons03 sheet", function()
    local Display = BuildCategories(FakeDeps())[3]
    local Labels = {}
    for i, Item in ipairs(Display.Items) do Labels[i] = Item.Label end
    CheckEq(table.concat(Labels, ","), "V,AP,NS,FD,MI,BGA OFF,BGA DARK,BGA PARTIAL", "labels")
    CheckEq(Display.Items[1].Sheet, "Icons03 6x3", "sheet")
    CheckEq(Display.Items[1].Frame, 0, "V frame")
    CheckEq(Display.Items[4].Frame, 3, "FD frame")
    CheckEq(Display.Items[5].Frame, 6, "MI frame")
    CheckEq(Display.Items[6].Frame, 7, "BGA OFF frame")
    CheckEq(Display.Items[6].InactiveFrame, 8, "BGA OFF inactive frame")
    CheckEq(Display.Items[7].Frame, 9, "BGA DARK frame")
    CheckEq(Display.Items[7].InactiveFrame, 10, "BGA DARK inactive frame")
    CheckEq(Display.Items[8].Frame, 11, "BGA PARTIAL frame")
    CheckEq(Display.Items[8].InactiveFrame, 12, "BGA PARTIAL inactive frame")
end)

Test("Display appearance badges toggle their mods", function()
    local D = FakeDeps()
    local Display = BuildCategories(D)[3]
    Display.Items[1].Apply(P1)
    CheckEq(D.Mods[P1].hidden, true, "V -> hidden")
    CheckEq(Display.Items[1].IsActive(P1), true, "V active")
    Display.Items[1].Apply(P1)
    CheckEq(D.Mods[P1].hidden, false, "V off")
    Display.Items[2].Apply(P1)
    CheckEq(D.Mods[P1].sudden, true, "AP -> sudden")
    Display.Items[3].Apply(P1)
    CheckEq(D.Mods[P1].stealth, true, "NS -> stealth")
    Display.Items[4].Apply(P1)
    CheckEq(D.Mods[P1].dark, true, "FD -> dark")
    Display.Items[5].Apply(P1)
    CheckEq(D.Mods[P1].mini, true, "MI -> mini")
end)

Test("Display BGA badges set the screen filter, exclusive, and toggle off", function()
    local D = FakeDeps()
    local Display = BuildCategories(D)[3]
    Display.Items[7].Apply(P1)
    CheckEq(D.Prefs[P1].ScreenFilter, 0.8, "BGA DARK -> 0.8")
    CheckEq(D.Prefs[P1].ScreenFilterSize, "Full", "full-screen filter")
    CheckEq(D.Prefs[P1].ScreenFilterColor, 2, "black filter, not the player color")
    CheckEq(Display.Items[7].IsActive(P1), true, "DARK active")
    CheckEq(Display.Items[6].IsActive(P1), false, "OFF inactive")
    Display.Items[6].Apply(P1)
    CheckEq(D.Prefs[P1].ScreenFilter, 1, "BGA OFF -> 1")
    CheckEq(Display.Items[7].IsActive(P1), false, "DARK now inactive")
    Display.Items[8].Apply(P1)
    CheckEq(D.Prefs[P1].ScreenFilter, 0.5, "BGA PARTIAL -> 0.5")
    Display.Items[8].Apply(P1)
    CheckEq(D.Prefs[P1].ScreenFilter, 0, "applying the active badge again turns the filter off")
    D.Prefs[P1].ScreenFilter = "0.8"
    CheckEq(Display.Items[7].IsActive(P1), true, "string value from the prefs file still matches")
end)

Test("Speed items: 13 badges from the Icons02 sheet", function()
    local C = BuildCategories(FakeDeps())
    local Speed = C[1]
    CheckEq(#Speed.Items, 13, "count")
    CheckEq(Speed.Items[1].Frame, 0, "1x frame")
    CheckEq(Speed.Items[13].Frame, 12, "DC frame")
    CheckEq(Speed.Items[1].Sheet, "Icons02 13x1", "sheet")
    CheckEq(Speed.Items[2].Label, "2x", "label")
end)

Test("Speed 2x sets AV 200 with Multiply", function()
    local D = FakeDeps({ AV = { [P1] = 575 }, AVType = { [P1] = "Constant" } })
    local Speed = BuildCategories(D)[1]
    Speed.Items[2].Apply(P1)
    CheckEq(D.AV[P1], 200, "AV")
    CheckEq(D.AVType[P1], false, "type")
end)

Test("Speed +0.25 and +0.5 add to the current AV", function()
    local D = FakeDeps()
    local Speed = BuildCategories(D)[1]
    Speed.Items[7].Apply(P1)
    CheckEq(D.AV[P1], 225, "+0.25")
    Speed.Items[8].Apply(P1)
    CheckEq(D.AV[P1], 275, "+0.5")
end)

Test("Speed EW/RV/AC/DC toggle their mods", function()
    local D = FakeDeps()
    local Speed = BuildCategories(D)[1]
    Speed.Items[9].Apply(P1)
    CheckEq(D.Mods[P1].expand, true, "EW on")
    CheckEq(Speed.Items[9].IsActive(P1), true, "EW active")
    Speed.Items[9].Apply(P1)
    CheckEq(D.Mods[P1].expand, false, "EW off")
    Speed.Items[10].Apply(P1)
    CheckEq(D.Mods[P1].randomspeed, true, "RV")
    Speed.Items[12].Apply(P1)
    CheckEq(D.Mods[P1].boost, true, "AC")
    Speed.Items[13].Apply(P1)
    CheckEq(D.Mods[P1].brake, true, "DC")
end)

Test("Speed AV badge switches to Auto (PIU auto velocity keeps BPM gimmicks)", function()
    local D = FakeDeps()
    local Speed = BuildCategories(D)[1]
    Speed.Items[11].Apply(P1)
    CheckEq(D.AVType[P1], "Auto", "type")
    CheckEq(Speed.Items[11].IsActive(P1), true, "active")
    D.AVType[P1] = "Constant"
    CheckEq(Speed.Items[11].IsActive(P1), false, "Constant is not AV")
end)

Test("Speed Nx is active only with Multiply and matching AV", function()
    local D = FakeDeps({ AV = { [P1] = 200 }, AVType = { [P1] = false } })
    local Speed = BuildCategories(D)[1]
    CheckEq(Speed.Items[2].IsActive(P1), true, "2x active")
    CheckEq(Speed.Items[3].IsActive(P1), false, "3x inactive")
    D.AVType[P1] = "Auto"
    CheckEq(Speed.Items[2].IsActive(P1), false, "2x inactive with Auto")
end)

Test("AutoVelocity steps clamp between 100 and 999", function()
    local D = FakeDeps({ AV = { [P1] = 950 }, AVType = { [P1] = "Constant" } })
    local AV = BuildCategories(D)[2]
    CheckEq(#AV.Items, 8, "6 steps + Auto + Constant")
    CheckEq(AV.Items[1].Label, "+100", "label 1")
    CheckEq(AV.Items[6].Label, "-100", "label 6")
    CheckEq(AV.Items[6].Frame, 5, "frame 6")
    CheckEq(AV.Items[1].Sheet, "Icons11 6x1", "sheet")
    AV.Items[1].Apply(P1)
    CheckEq(D.AV[P1], 999, "clamp high")
    D.AV[P1] = 150
    AV.Items[6].Apply(P1)
    CheckEq(D.AV[P1], 100, "clamp low")
    D.AV[P1] = 200
    AV.Items[2].Apply(P1)
    CheckEq(D.AV[P1], 210, "+10")
    AV.Items[3].Apply(P1)
    CheckEq(D.AV[P1], 211, "+1")
    AV.Items[4].Apply(P1)
    CheckEq(D.AV[P1], 210, "-1")
    AV.Items[5].Apply(P1)
    CheckEq(D.AV[P1], 200, "-10")
end)

Test("AutoVelocity type badges: Auto and Constant only", function()
    local D = FakeDeps({ AVType = { [P1] = "Auto" } })
    local AV = BuildCategories(D)[2]
    CheckEq(AV.Items[7].Label, "Auto", "7")
    CheckEq(AV.Items[8].Label, "Constant", "8")
    CheckEq(AV.Items[7].Sheet, nil, "generic badge")
    CheckEq(AV.Items[7].IsActive(P1), true, "Auto active")
    CheckEq(AV.Items[8].IsActive(P1), false, "Constant inactive")
    AV.Items[8].Apply(P1)
    CheckEq(D.AVType[P1], "Constant", "Constant applied")
    CheckEq(AV.Items[8].IsActive(P1), true, "Constant active")
end)

Test("AutoVelocity steps mean auto velocity: Multiply switches to Auto, an explicit Constant is kept", function()
    local D = FakeDeps({ AV = { [P1] = 200 }, AVType = { [P1] = false } })
    local AV = BuildCategories(D)[2]
    AV.Items[2].Apply(P1)
    CheckEq(D.AV[P1], 210, "+10")
    CheckEq(D.AVType[P1], "Auto", "Multiply -> Auto")
    D.AVType[P1] = "Constant"
    AV.Items[2].Apply(P1)
    CheckEq(D.AVType[P1], "Constant", "Constant kept")
end)

Test("AutoVelocity Value shows the AV, defaulting to 200", function()
    local D = FakeDeps()
    local AV = BuildCategories(D)[2]
    CheckEq(AV.Value(P1), "200", "value")
    D.AV[P1] = nil
    CheckEq(AV.Value(P1), "200", "default when unset")
    D.AV[P1] = 580
    CheckEq(AV.Value(P1), "580", "value 580")
end)

Test("NoteSkin items follow NoteSkinNames and apply the skin", function()
    local D = FakeDeps()
    local NS = BuildCategories(D)[4]
    CheckEq(#NS.Items, 3, "count")
    CheckEq(NS.Items[1].Label, "default", "1")
    CheckEq(NS.Items[3].Label, "Infinity", "3")
    CheckEq(NS.Items[3].Sheet, nil, "no sheet")
    NS.Items[3].Apply(P1)
    CheckEq(D.Skin[P1], "Infinity", "applied")
    CheckEq(NS.Items[3].IsActive(P1), true, "active")
    CheckEq(NS.Items[1].IsActive(P1), false, "inactive")
end)

Test("NoteSkin DefaultItem is the current skin, case-insensitive, else 1", function()
    local D = FakeDeps({ Skin = { [P1] = "INFINITY" } })
    local NS = BuildCategories(D)[4]
    CheckEq(NS.DefaultItem(P1), 3, "current skin")
    D.Skin[P1] = "missing"
    CheckEq(NS.DefaultItem(P1), 1, "fallback")
end)

Test("Descriptions come from Text keys", function()
    local C = BuildCategories(FakeDeps())
    CheckEq(C[1].Description, "Speed_Desc", "Speed")
    CheckEq(C[2].Description, "AutoVelocity_Desc", "AV")
    CheckEq(C[1].Items[9].Description, "Speed_EW", "EW item")
    CheckEq(C[3].Description, "Display_Desc", "Display")
    CheckEq(C[3].Items[7].Description, "Display_BGADark", "BGA DARK item")
    CheckEq(C[4].Items[1].Description, "NoteSkin_Desc", "noteskin items share the category description")
end)
