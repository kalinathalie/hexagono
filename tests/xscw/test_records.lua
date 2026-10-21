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
