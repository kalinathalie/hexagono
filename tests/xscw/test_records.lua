-- Select.Records: record (high score) labels shown above the difficulty bubbles.

Test("Records.Label formats the integer score and hides missing ones", function()
    local Scores = { [1] = { [10] = 878123.0 }, [2] = {} }
    local R = LoadModule("Select.Records.lua")({ Players = { 1, 2 },
        GetHighScore = function(pn, song, steps) return Scores[pn][steps] end })
    CheckEq(R.Label(1, "song", 10), "878123", "P1 score")
    CheckEq(R.Label(2, "song", 10), "", "P2 none")
    CheckEq(R.Label(1, "song", 11), "", "no score")
    local L = R.LabelsFor("song", { 10, 11 })
    CheckEq(L[1][1], "878123", "list P1"); CheckEq(L[1][2], "", "list P2"); CheckEq(L[2][1], "", "list none")
end)

Test("Records.GradeFrame maps the theme grade names to the XSanity grade label frames", function()
    local R = LoadModule("Select.Records.lua")({ Players = { 1 }, GetHighScore = function() return nil end })
    CheckEq(R.GradeFrame("Pass3PS"), 0, "SSS+"); CheckEq(R.GradeFrame("Pass3S"), 1, "SSS")
    CheckEq(R.GradeFrame("Pass2PS"), 2, "SS+"); CheckEq(R.GradeFrame("Pass2S"), 3, "SS")
    CheckEq(R.GradeFrame("PassS"), 5, "S"); CheckEq(R.GradeFrame("Pass2PA"), 8, "AA+")
    CheckEq(R.GradeFrame("FailA"), 11, "failed A still shows A"); CheckEq(R.GradeFrame("PassF"), 15, "F")
    CheckEq(R.GradeFrame("PassZ"), nil, "unknown"); CheckEq(R.GradeFrame(nil), nil, "nil")
end)

Test("Records.Label ignores non-numeric and zero scores", function()
    local R = LoadModule("Select.Records.lua")({ Players = { 1 },
        GetHighScore = function(pn, song, steps) return ({ [1] = "x", [2] = 0, [3] = 12.9 })[steps] end })
    CheckEq(R.Label(1, "song", 1), "", "string")
    CheckEq(R.Label(1, "song", 2), "", "zero")
    CheckEq(R.Label(1, "song", 3), "12", "floored")
end)

Test("Records.GradeName and PlateName give the Phoenix record icon names", function()
    local R = LoadModule("Select.Records.lua")({ Players = { 1 }, GetHighScore = function() return nil end })
    CheckEq(R.GradeName("Pass2S"), "R_SS", "SS"); CheckEq(R.GradeName("Pass2PA"), "R_AA+", "AA+")
    CheckEq(R.GradeName("Pass3PS"), "R_SSS+", "SSS+"); CheckEq(R.GradeName("PassB"), "R_B", "B")
    CheckEq(R.GradeName("FailA"), "B_A", "failed: broken icon"); CheckEq(R.GradeName("PassZ"), nil, "unknown")
    CheckEq(R.PlateName("MarvelousGame"), "MG", "marvelous"); CheckEq(R.PlateName("PerfectGame"), "PG", "perfect")
    CheckEq(R.PlateName("RoughGame"), "RG", "rough"); CheckEq(R.PlateName("FailGame"), nil, "no plate on fail")
end)

Test("Records.Best skips broken plays (stage failed) and keeps the best cleared one", function()
    local R = LoadModule("Select.Records.lua")({ Players = { 1 }, GetHighScore = function() return nil end })
    local function Score(Grade, Points)
        return { GetGrade = function() return Grade end, GetScore = function() return Points end }
    end
    local Broken, Cleared, Lower = Score("Grade_Failed", 950000), Score("Grade_Tier05", 800000), Score("Grade_Tier07", 600000)
    CheckEq(R.Best({ Broken, Cleared, Lower }), Cleared, "a broken play above a cleared one")
    CheckEq(R.Best({ Cleared, Broken }), Cleared, "cleared first")
    CheckEq(R.Best({ Broken }), nil, "only broken plays: no record")
    CheckEq(R.Best({}), nil, "no plays")
    CheckEq(R.Best(nil), nil, "no list")
end)
