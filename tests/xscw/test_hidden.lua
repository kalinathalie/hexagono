-- Chart.HiddenNotes: notes marked hidden in StepF2/SSC charts ({2|h|0|0}).

local Hidden = LoadModule("Chart.HiddenNotes.lua")

local SSC = [[
#TITLE:Test;
#NOTEDATA:;
#STEPSTYPE:pump-single;
#DESCRIPTION:S3;
#DIFFICULTY:Easy;
#METER:3;
#NOTES:
10000
00000
00000
00000
;
#NOTEDATA:;
#CHARTNAME:[GIMMICK] test;
#STEPSTYPE:pump-single;
#DESCRIPTION:S17 INFOBAR TITLE;
#DIFFICULTY:Edit;
#METER:17;
#NOTES:
10000
{2|h|0|0}0000
00000
{3|h|0|0}0000
,
00{1|h|0|0}00
0000{M|n|1|0}
// comment
00000
00000
;
]]

local function Find(over)
    local want = { StepsType = "pump-single", Description = "S17 INFOBAR TITLE", Meter = 17, Difficulty = "Edit", ChartName = "[GIMMICK] test" }
    for k, v in pairs(over or {}) do want[k] = v end
    return Hidden.Find(SSC, want)
end

Test("HiddenNotes: Find picks the chart with the same type, description, meter and difficulty", function()
    local Notes = Find()
    Check(Notes ~= nil, "found")
    Check(Notes and Notes:find("{2|h|0|0}", 1, true) ~= nil, "the gimmick chart")
    CheckEq(Hidden.Find(SSC, { StepsType = "pump-single", Description = "S3", Meter = 3, Difficulty = "Easy" }):find("{", 1, true), nil, "the plain chart")
    CheckEq(Find({ Meter = 18 }), nil, "no chart with another meter")
end)

Test("HiddenNotes: a hidden hold is hidden from its head to its tail; the visible tap before it stays", function()
    local R = Hidden.Regions(Find())
    CheckEq(#R, 2, "two hidden notes")
    local Hold = R[1]
    CheckEq(Hold[3], 1, "column 1 (1-based)")
    -- 4 rows per measure: the head is on beat 1, the tail on beat 3
    Check(Hold[1] > 0.99 and Hold[1] < 1, "starts just before the head at beat 1 (got " .. Hold[1] .. ")")
    Check(Hold[2] > 3 and Hold[2] < 3.01, "ends just after the tail at beat 3 (got " .. Hold[2] .. ")")
    Check(Hold[1] > 0, "the tap at beat 0 is not inside")
end)

Test("HiddenNotes: a hidden tap gets a tiny region on its own column; normal and fake notes none", function()
    local R = Hidden.Regions(Find())
    local Tap = R[2]
    CheckEq(Tap[3], 3, "column 3")
    Check(Tap[1] < 4 and Tap[2] > 4 and Tap[2] - Tap[1] < 0.05, "around beat 4")
end)

Test("HiddenNotes: charts without hidden notes give no regions", function()
    CheckEq(#Hidden.Regions(Hidden.Find(SSC, { StepsType = "pump-single", Description = "S3", Meter = 3, Difficulty = "Easy" })), 0, "none")
    CheckEq(#Hidden.Regions(nil), 0, "nil notes")
end)
