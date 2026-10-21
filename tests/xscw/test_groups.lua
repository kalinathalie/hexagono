-- Select.GroupCards and GroupInfo: card kind/title/image and the description line.

local Cards = LoadModule("Select.GroupCards.lua")

Test("GroupCards classifies and titles subgroups", function()
    CheckEq(Cards.Kind("Group", "14 - XX"), "version", "version"); CheckEq(Cards.Title("Group", "14 - XX"), "XX", "strip number")
    CheckEq(Cards.Title("Group", "01 - 1ST~3RD"), "1ST~3RD", "strip number 2")
    CheckEq(Cards.Kind("Single", "Single 17"), "level", "level"); CheckEq(Cards.Title("Single", "Single 17"), "S17", "S17")
    CheckEq(Cards.Title("Double", "Double 22"), "D22", "D22"); CheckEq(Cards.Title("Half-Double", "Half-Double 10"), "HD10", "HD10")
    CheckEq(Cards.Kind("Title", "A"), "letter", "letter"); CheckEq(Cards.Title("Title", "#"), "#", "#")
    CheckEq(Cards.Kind("Artist", "B"), "letter", "artist letter")
    CheckEq(Cards.Kind("Special", "Co-op"), "special", "special"); CheckEq(Cards.Title("Special", "All Tunes"), "All Tunes", "special title")
    CheckEq(Cards.Kind(nil, "Group"), "category", "category"); CheckEq(Cards.Title(nil, "Half-Double"), "Half-Double", "category title")
    CheckEq(Cards.Image("Group", "14 - XX", "/Songs/14 - XX/banner.png"), "/Songs/14 - XX/banner.png", "banner")
    CheckEq(Cards.Image("Single", "Single 17", "/x.png"), nil, "no image for levels")
    CheckEq(Cards.Image("Group", "14 - XX", ""), nil, "empty banner path")
end)

Test("GroupCards titles unrated and unnumbered level groups like the bubbles do", function()
    CheckEq(Cards.Title("Single", "Single 99"), "S??", "99 is unrated, as on the bubble")
    CheckEq(Cards.Title("Double", "Double ??"), "Double ??", "no digits: the name itself")
    CheckEq(Cards.Title("Half-Double", "Half-Double 07"), "HD07", "keeps the digits")
end)

Test("GroupInfo describes known groups and falls back", function()
    local Known = { ["Group_14 - XX"] = "Músicas do XX", ["Category_Double"] = "Charts double", Letter = "Por letra",
        Fallback_Version = "Músicas da versão %s", Fallback_Level = "Todas as músicas com chart %s" }
    local Info = LoadModule("GroupInfo.lua")(function(k) return Known[k] or "" end)
    CheckEq(Info.Describe("Group", "14 - XX"), "Músicas do XX", "known group")
    CheckEq(Info.Describe("Group", "99 - NOVA"), "Músicas da versão NOVA", "version fallback")
    CheckEq(Info.Describe("Single", "Single 17"), "Todas as músicas com chart SINGLE 17", "level fallback")
    CheckEq(Info.Describe("Title", "A"), "Por letra", "letter")
    CheckEq(Info.Describe(nil, "Double"), "Charts double", "category")
    CheckEq(Info.Describe("Special", "Co-op"), "Co-op", "special without string falls back to its name")
end)
