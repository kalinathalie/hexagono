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
    }
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
    CheckEq(C[3].Name, "NoteSkin", "3")
    CheckEq(C[4].Name, "Exit", "4")
    CheckEq(C[1].Kind, "items", "Speed kind")
    CheckEq(C[2].Kind, "items", "AV kind")
    CheckEq(C[3].Kind, "noteskin", "NoteSkin kind")
    CheckEq(C[4].Kind, "exit", "Exit kind")
    CheckEq(C[1].Title, "01_title", "Speed title")
    CheckEq(C[2].Title, "11_title", "AV title")
    CheckEq(C[3].Title, "03_title", "NoteSkin title")
    CheckEq(C[4].Title, nil, "Exit has no title image")
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

Test("Speed AV badge switches to Constant", function()
    local D = FakeDeps()
    local Speed = BuildCategories(D)[1]
    Speed.Items[11].Apply(P1)
    CheckEq(D.AVType[P1], "Constant", "type")
    CheckEq(Speed.Items[11].IsActive(P1), true, "active")
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
    local D = FakeDeps({ AV = { [P1] = 950 } })
    local AV = BuildCategories(D)[2]
    CheckEq(#AV.Items, 9, "6 steps + 3 types")
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

Test("AutoVelocity type badges", function()
    local D = FakeDeps({ AVType = { [P1] = "Auto" } })
    local AV = BuildCategories(D)[2]
    CheckEq(AV.Items[7].Label, "Multiply", "7")
    CheckEq(AV.Items[8].Label, "Auto", "8")
    CheckEq(AV.Items[9].Label, "Constant", "9")
    CheckEq(AV.Items[7].Sheet, nil, "generic badge")
    CheckEq(AV.Items[8].IsActive(P1), true, "Auto active")
    CheckEq(AV.Items[7].IsActive(P1), false, "Multiply inactive")
    AV.Items[9].Apply(P1)
    CheckEq(D.AVType[P1], "Constant", "Constant applied")
    CheckEq(AV.Items[9].IsActive(P1), true, "Constant active")
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
    local NS = BuildCategories(D)[3]
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
    local NS = BuildCategories(D)[3]
    CheckEq(NS.DefaultItem(P1), 3, "current skin")
    D.Skin[P1] = "missing"
    CheckEq(NS.DefaultItem(P1), 1, "fallback")
end)

Test("Descriptions come from Text keys", function()
    local C = BuildCategories(FakeDeps())
    CheckEq(C[1].Description, "Speed_Desc", "Speed")
    CheckEq(C[2].Description, "AutoVelocity_Desc", "AV")
    CheckEq(C[1].Items[9].Description, "Speed_EW", "EW item")
    CheckEq(C[4].Label, "Exit", "Exit label")
end)
