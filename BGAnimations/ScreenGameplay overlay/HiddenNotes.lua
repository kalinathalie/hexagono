-- Hides the notes a chart marks as hidden ({2|h|0|0} in SSC/StepF2 charts, used by
-- gimmick charts such as Ugly Dee S17): they stay judged, as on the arcade.
local pn = ...
local Hidden = LoadModule("Chart.HiddenNotes.lua")

local function Want(Steps)
    return {
        StepsType = ToEnumShortString(Steps:GetStepsType()):lower():gsub("_", "-"),
        Description = Steps:GetDescription(),
        Meter = Steps:GetMeter(),
        Difficulty = ToEnumShortString(Steps:GetDifficulty()),
        ChartName = Steps.GetChartName and Steps:GetChartName() or nil,
    }
end

return Def.Actor {
    OnCommand=function(self)
        local Steps = GAMESTATE:GetCurrentSteps(pn)
        local File = Steps and Steps:GetFilename() or ""
        if not File:lower():find("%.ssc$") then return end
        local Text = lua.ReadFile(File)
        if not Text or not Text:find("|h|", 1, true) then return end
        local Regions = Hidden.Regions(Hidden.Find(Text, Want(Steps)))
        if #Regions == 0 then return end
        local Player = SCREENMAN:GetTopScreen():GetChild("Player" .. ToEnumShortString(pn))
        local Field = Player and Player:GetChild("NoteField")
        if Field then
            Field:add_hidden_regions(Regions)
            Trace("HiddenNotes: " .. #Regions .. " hidden notes for " .. ToEnumShortString(pn))
        end
    end,
}
