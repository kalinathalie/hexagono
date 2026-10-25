-- Profile.Slots: reserved empty profiles, so a player can create a profile with
-- the pad. OutFox's Lua cannot create a local profile (only the operator menu
-- can) and reads the profile folder only at startup, but it can rename and save
-- one. A few empty profiles named MARKER are kept in Save/LocalProfiles: they
-- are hidden from the profile list, and "create" renames the first free one.
-- Each creation writes a new reserved folder, available at the next start.
-- Pure Lua, no engine calls.
--
--   VisibleList(profiles) -> { { Kind = "guest"|"profile"|"create", Engine, Name } }
--       profiles = { { Index = local index (0-based), Name = display name } }
--       Engine = index for ScreenSelectProfile:SetProfileIndex (0 = guest)
--   FirstFree(profiles, used) -> local index of a reserved profile, or nil
--   NextId(ids) -> lowest free "%08d" id
--   Files(guid, priority) -> { ["Editable.ini"], ["Stats.xml"], ["Type.ini"] } contents
--   CleanName(text) -> trimmed name (12 characters at most) or nil

local Slots = {}

Slots.MARKER = "~HEXAGONO_SLOT~"
Slots.POOL = 6
Slots.MAX_NAME = 12

function Slots.IsSlot(name) return name == Slots.MARKER end

function Slots.VisibleList(profiles)
    local List = { { Kind = "guest", Engine = 0 } }
    for _, P in ipairs(profiles) do
        if not Slots.IsSlot(P.Name) then
            List[#List + 1] = { Kind = "profile", Engine = P.Index + 1, Name = P.Name }
        end
    end
    List[#List + 1] = { Kind = "create" }
    return List
end

function Slots.FirstFree(profiles, used)
    for _, P in ipairs(profiles) do
        if Slots.IsSlot(P.Name) and not used[P.Index] then return P.Index end
    end
    return nil
end

function Slots.NextId(ids)
    local Taken = {}
    for _, id in ipairs(ids) do
        local n = tonumber(id)
        if n then Taken[n] = true end
    end
    local n = 0
    while Taken[n] do n = n + 1 end
    return string.format("%08d", n)
end

function Slots.Files(guid, priority)
    local M = Slots.MARKER
    return {
        ["Editable.ini"] = table.concat({
            "[Editable]", "BirthYear=0", "CharacterID=default", "DisplayName=" .. M,
            "IgnoreStepCountCalories=0", "IsMale=0", "LastUsedHighScoreName=", "Voomax=0.000000", "WeightPounds=0", "",
        }, "\n"),
        ["Type.ini"] = table.concat({
            "[ListPosition]", "Priority=" .. priority, "Type=Normal", "",
            "[Online]", "InputType=0", "Registered=0", "Token=", "",
        }, "\n"),
        ["Stats.xml"] = table.concat({
            '<?xml version="1.0" encoding="UTF-8" ?>', "", "<Stats>", "<GeneralData>",
            "<DisplayName>" .. M .. "</DisplayName>", "<CharacterID>default</CharacterID>",
            "<LastUsedHighScoreName></LastUsedHighScoreName>", "<WeightPounds>0</WeightPounds>",
            "<Voomax>0.000000</Voomax>", "<BirthYear>0</BirthYear>", "<IgnoreStepCountCalories>0</IgnoreStepCountCalories>",
            "<IsMale>0</IsMale>", "<IsMachine>0</IsMachine>", "<Guid>" .. guid .. "</Guid>",
            "<SortOrder>Invalid</SortOrder>", "<LastDifficulty>Invalid</LastDifficulty>",
            "<LastCourseDifficulty>Invalid</LastCourseDifficulty>", "<Song Dir=''/>", "<Course/>",
            "<CurrentCombo>0</CurrentCombo>", "<TotalSessions>0</TotalSessions>", "<TotalSessionSeconds>0</TotalSessionSeconds>",
            "<TotalGameplaySeconds>0</TotalGameplaySeconds>", "<TotalCaloriesBurned>0.000000</TotalCaloriesBurned>",
            "<GoalType>2</GoalType>", "<GoalCalories>0</GoalCalories>", "<GoalSeconds>0</GoalSeconds>",
            "<TotalDancePoints>0</TotalDancePoints>", "<NumExtraStagesPassed>0</NumExtraStagesPassed>",
            "<NumExtraStagesFailed>0</NumExtraStagesFailed>", "<NumToasties>0</NumToasties>",
            "<TotalTapsAndHolds>0</TotalTapsAndHolds>", "<TotalJumps>0</TotalJumps>", "<TotalHolds>0</TotalHolds>",
            "<TotalRolls>0</TotalRolls>", "<TotalMines>0</TotalMines>", "<TotalHands>0</TotalHands>", "<TotalLifts>0</TotalLifts>",
            "<DefaultModifiers/>", "<FavSongs/>", "<Unlocks/>", "<NumSongsPlayedByPlayMode/>", "<NumSongsPlayedByStyle/>",
            "<NumSongsPlayedByDifficulty/>", "<NumSongsPlayedByMeter/>", "<NumTotalSongsPlayed>0</NumTotalSongsPlayed>",
            "<NumStagesPassedByPlayMode/>", "<NumStagesPassedByGrade/>", "<UserTable></UserTable>",
            "</GeneralData>", "<SongScores/>", "<CourseScores/>", "<CategoryScores/>", "<ScreenshotData/>", "<CalorieData/>",
            "</Stats>", "",
        }, "\n"),
    }
end

function Slots.CleanName(text)
    local Name = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if Name == "" or Slots.IsSlot(Name) then return nil end
    return Name:sub(1, Slots.MAX_NAME)
end

return Slots
